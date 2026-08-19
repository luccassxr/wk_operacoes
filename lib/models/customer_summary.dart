class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.cpf,
    required this.points,
  });

  final String id;
  final String name;
  final String cpf;
  final int points;

  String get maskedCpf {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF não informado';
    return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
  }
}
