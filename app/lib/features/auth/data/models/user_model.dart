import '../../domain/entities/user_entity.dart';

/// User data model - handles JSON serialization.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.avatarUrl,
    super.phoneNumber,
    super.employeeId,
    super.department,
    super.position,
    super.workLocation,
    super.shift,
    super.createdAt,
    super.joinDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      employeeId: json['employee_id'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      workLocation: json['work_location'] as String?,
      shift: json['shift'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      joinDate: json['join_date'] != null
          ? DateTime.parse(json['join_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'employee_id': employeeId,
      'department': department,
      'position': position,
      'work_location': workLocation,
      'shift': shift,
      'created_at': createdAt?.toIso8601String(),
      'join_date': joinDate?.toIso8601String(),
    };
  }
}
