import 'package:flutter_test/flutter_test.dart';
import 'package:wk_operacoes/models/customer_summary.dart';

void main() {
  test('mascara CPF do cliente para exibição operacional', () {
    const customer = CustomerSummary(
      id: 'uid-demo',
      name: 'Cliente Teste',
      cpf: '12345678901',
      points: 120,
    );

    expect(customer.maskedCpf, '***.456.789-**');
  });
}
