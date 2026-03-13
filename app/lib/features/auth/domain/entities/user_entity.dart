import 'package:equatable/equatable.dart';

/// User domain entity - pure business object.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, fullName, avatarUrl, phoneNumber, createdAt];
}
