import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'firebase_options.dart';
import 'models/customer_summary.dart';
import 'models/employee_model.dart';
import 'services/operations_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WKOperacoesApp());
}

class WKOperacoesApp extends StatelessWidget {
  const WKOperacoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WK Operações',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF15325B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  final service = OperationsService();
  late Future<EmployeeModel?> future;

  @override
  void initState() {
    super.initState();
    future = service.restoreEmployee();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmployeeModel?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return LoginScreen(service: service);
        }
        return HomeScreen(service: service, employee: snapshot.data!);
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.service});
  final OperationsService service;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final employee = await widget.service.login(email.text, password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(service: widget.service, employee: employee),
        ),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.local_gas_station, size: 58),
                      const SizedBox(height: 12),
                      Text('WK Operações', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Acesso interno de funcionários', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail corporativo')),
                      const SizedBox(height: 12),
                      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: loading ? null : submit,
                        icon: loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.service, required this.employee});
  final OperationsService service;
  final EmployeeModel employee;

  Future<void> logout(BuildContext context) async {
    await service.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen(service: service)), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WK Operações'),
        actions: [IconButton(onPressed: () => logout(context), icon: const Icon(Icons.logout), tooltip: 'Sair')],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(employee.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(employee.stationName),
                  const SizedBox(height: 2),
                  Text('Perfil: ${employee.role}'),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: () async {
                final customer = await Navigator.of(context).push<CustomerSummary>(MaterialPageRoute(builder: (_) => ScannerScreen(service: service)));
                if (!context.mounted || customer == null) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => FuelingScreen(service: service, employee: employee, customer: customer)));
              },
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text('Ler QR do cliente'),
            ),
            const SizedBox(height: 12),
            const Text('O QR identifica o cliente pelo UID do Firebase. O WK Operações não cria cadastros de clientes.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.service});
  final OperationsService service;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool processing = false;
  String? error;

  Future<void> process(String value) async {
    if (processing) return;
    setState(() {
      processing = true;
      error = null;
    });
    try {
      final customer = await widget.service.findCustomerFromQr(value);
      if (!mounted) return;
      Navigator.of(context).pop(customer);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identificar cliente')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final value = capture.barcodes.firstOrNull?.rawValue;
                if (value != null) process(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              if (processing) const LinearProgressIndicator(),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => setState(() { error = null; processing = false; }), child: const Text('Tentar novamente')),
              ] else
                const Text('Aponte a câmera para o QR exibido no WK Cliente.', textAlign: TextAlign.center),
            ]),
          ),
        ],
      ),
    );
  }
}

class FuelingScreen extends StatefulWidget {
  const FuelingScreen({super.key, required this.service, required this.employee, required this.customer});
  final OperationsService service;
  final EmployeeModel employee;
  final CustomerSummary customer;

  @override
  State<FuelingScreen> createState() => _FuelingScreenState();
}

class _FuelingScreenState extends State<FuelingScreen> {
  final amount = TextEditingController();
  final liters = TextEditingController();
  String fuel = 'Gasolina comum';
  bool saving = false;
  String? error;

  double? number(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> save() async {
    final amountValue = number(amount.text);
    final litersValue = liters.text.trim().isEmpty ? null : number(liters.text);
    if (amountValue == null) {
      setState(() => error = 'Informe um valor válido.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      final earned = await widget.service.registerFueling(
        employee: widget.employee,
        customer: widget.customer,
        amount: amountValue,
        fuel: fuel,
        liters: litersValue,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Abastecimento registrado'),
          content: Text('${widget.customer.name} recebeu $earned pontos.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Concluir'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    liters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${customer.maskedCpf}\nSaldo atual: ${customer.points} pontos'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          Text('Posto: ${widget.employee.stationName}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: fuel,
            decoration: const InputDecoration(labelText: 'Combustível'),
            items: const [
              DropdownMenuItem(value: 'Gasolina comum', child: Text('Gasolina comum')),
              DropdownMenuItem(value: 'Gasolina aditivada', child: Text('Gasolina aditivada')),
              DropdownMenuItem(value: 'Etanol', child: Text('Etanol')),
              DropdownMenuItem(value: 'Diesel S10', child: Text('Diesel S10')),
              DropdownMenuItem(value: 'Diesel S500', child: Text('Diesel S500')),
            ],
            onChanged: (value) => setState(() => fuel = value ?? fuel),
          ),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor do abastecimento (R$)', prefixText: 'R$ ')),
          const SizedBox(height: 12),
          TextField(controller: liters, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Litros (opcional)')),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: saving ? null : save,
            icon: saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle),
            label: const Text('Confirmar abastecimento'),
          ),
        ],
      ),
    );
  }
}
