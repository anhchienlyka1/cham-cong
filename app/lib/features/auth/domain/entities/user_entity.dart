import 'package:equatable/equatable.dart';

/// User domain entity - pure business object.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? employeeId;
  final String? department;
  final String? position;
  final String? workLocation;
  final String? shift;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.employeeId,
    this.department,
    this.position,
    this.workLocation,
    this.shift,
    this.createdAt,
  });

  /// Tạo bản sao UserEntity với các trường được cập nhật
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? employeeId,
    String? department,
    String? position,
    String? workLocation,
    String? shift,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      position: position ?? this.position,
      workLocation: workLocation ?? this.workLocation,
      shift: shift ?? this.shift,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        phoneNumber,
        employeeId,
        department,
        position,
        workLocation,
        shift,
        createdAt,
      ];
}
