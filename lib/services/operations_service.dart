import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_summary.dart';
import '../models/employee_model.dart';

class OperationsException implements Exception {
  const OperationsException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OperationsService {
  OperationsService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Future<EmployeeModel?> restoreEmployee() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _loadAuthorizedEmployee(user.uid, signOutOnFailure: true);
  }

  Future<EmployeeModel> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const OperationsException('Não foi possível autenticar o funcionário.');
      }
      return await _loadAuthorizedEmployee(user.uid, signOutOnFailure: true);
    } on FirebaseAuthException catch (error) {
      throw OperationsException(_authMessage(error.code));
    }
  }

  Future<EmployeeModel> _loadAuthorizedEmployee(
    String uid, {
    required bool signOutOnFailure,
  }) async {
    final doc = await _firestore.collection('employees').doc(uid).get();
    if (!doc.exists) {
      if (signOutOnFailure) await _auth.signOut();
      throw const OperationsException('Este usuário não possui acesso ao WK Operações.');
    }
    final employee = EmployeeModel.fromMap(uid, doc.data()!);
    const allowedRoles = {'attendant', 'manager', 'admin'};
    if (!employee.active || !allowedRoles.contains(employee.role)) {
      if (signOutOnFailure) await _auth.signOut();
      throw const OperationsException('Acesso do funcionário está desativado ou sem permissão.');
    }
    if (employee.stationId.isEmpty || employee.stationName.isEmpty) {
      if (signOutOnFailure) await _auth.signOut();
      throw const OperationsException('Funcionário sem posto vinculado.');
    }
    return employee;
  }

  String parseCustomerId(String qrValue) {
    final value = qrValue.trim();
    const prefix = 'WKCLIENT:';
    if (!value.startsWith(prefix)) {
      throw const OperationsException('QR inválido. Use o QR do WK Cliente.');
    }
    final id = value.substring(prefix.length).trim();
    if (id.isEmpty) throw const OperationsException('QR do cliente está incompleto.');
    return id;
  }

  Future<CustomerSummary> findCustomerFromQr(String qrValue) async {
    final customerId = parseCustomerId(qrValue);
    final customerDoc = await _firestore.collection('customers').doc(customerId).get();
    if (!customerDoc.exists) {
      throw const OperationsException('Cliente não encontrado.');
    }
    final data = customerDoc.data()!;
    if (data['active'] == false) {
      throw const OperationsException('Cadastro do cliente está desativado.');
    }

    final tx = await customerDoc.reference.collection('transactions').get();
    var points = 0;
    for (final item in tx.docs) {
      points += (item.data()['points'] as num?)?.toInt() ?? 0;
    }

    return CustomerSummary(
      id: customerId,
      name: data['name']?.toString() ?? 'Cliente WK',
      cpf: data['cpf']?.toString() ?? '',
      points: points,
    );
  }

  Future<int> registerFueling({
    required EmployeeModel employee,
    required CustomerSummary customer,
    required double amount,
    required String fuel,
    double? liters,
  }) async {
    if (amount <= 0) throw const OperationsException('Informe um valor de abastecimento válido.');
    if (fuel.trim().isEmpty) throw const OperationsException('Selecione o combustível.');
    if (liters != null && liters <= 0) {
      throw const OperationsException('A quantidade de litros deve ser maior que zero.');
    }

    final authUser = _auth.currentUser;
    if (authUser == null || authUser.uid != employee.id) {
      throw const OperationsException('Sessão do funcionário inválida. Entre novamente.');
    }

    final points = amount.truncate();
    final transaction = _firestore
        .collection('customers')
        .doc(customer.id)
        .collection('transactions')
        .doc();

    await transaction.set({
      'customerId': customer.id,
      'date': FieldValue.serverTimestamp(),
      'stationId': employee.stationId,
      'stationName': employee.stationName,
      'amount': amount,
      'fuel': fuel.trim(),
      'liters': liters,
      'points': points,
      'type': 'fueling',
      'operatorId': employee.id,
      'operatorName': employee.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return points;
  }

  Future<void> logout() => _auth.signOut();

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha inválidos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Não foi possível entrar no WK Operações.';
    }
  }
}
