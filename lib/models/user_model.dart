class User {
  final String email;
  final String fullName;
  final String? phone;
  final String? employeeId;
  final String userType;

  User({
    required this.email,
    required this.fullName,
    this.phone,
    this.employeeId,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json, String userType) {
    return User(
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      employeeId: json['employee_id'],
      userType: userType,
    );
  }
}
