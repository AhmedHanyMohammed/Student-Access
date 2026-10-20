class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final int? assignedCategoryId;
  final String? assignedCategoryName;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'Student',
    this.assignedCategoryId,
    this.assignedCategoryName,
  });

  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'superadmin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'Student',
      assignedCategoryId: json['assignedCategoryId'] as int?,
      assignedCategoryName: json['assignedCategoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'assignedCategoryId': assignedCategoryId,
    'assignedCategoryName': assignedCategoryName,
  };
}
