class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.stationId,
    required this.stationName,
    required this.active,
  });

  final String id;
  final String name;
  final String role;
  final String stationId;
  final String stationName;
  final bool active;

  factory EmployeeModel.fromMap(String id, Map<String, dynamic> data) {
    return EmployeeModel(
      id: id,
      name: data['name']?.toString() ?? 'Funcionário WK',
      role: data['role']?.toString() ?? '',
      stationId: data['stationId']?.toString() ?? '',
      stationName: data['stationName']?.toString() ?? '',
      active: data['active'] == true,
    );
  }
}
