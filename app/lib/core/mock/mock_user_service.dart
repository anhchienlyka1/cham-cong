import 'dart:convert';

import 'package:flutter/services.dart';

/// Thông tin user mock – ánh xạ trực tiếp từ assets/mock/user.json
class MockUser {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? avatarUrl;
  final String department;
  final String position;
  final String workplace;
  final String employeeCode;
  final String status;
  final DateTime? createdAt;

  const MockUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.avatarUrl,
    required this.department,
    required this.position,
    required this.workplace,
    required this.employeeCode,
    required this.status,
    this.createdAt,
  });

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: (json['phone_number'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      department: (json['department'] as String?) ?? '',
      position: (json['position'] as String?) ?? '',
      workplace: (json['workplace'] as String?) ?? '',
      employeeCode: (json['employee_code'] as String?) ?? json['id'] as String,
      status: (json['status'] as String?) ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isActive => status == 'active';
}

/// Singleton service – gọi [MockUserService.instance] từ bất cứ đâu
class MockUserService {
  MockUserService._();
  static final MockUserService instance = MockUserService._();

  MockUser? _user;

  /// Phải gọi trước khi dùng (trong [configureDependencies])
  Future<void> load() async {
    if (_user != null) return;
    final raw = await rootBundle.loadString('assets/mock/user.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _user = MockUser.fromJson(json);
  }

  /// Trả về user mock. Throw nếu chưa gọi [load].
  MockUser get currentUser {
    assert(_user != null, 'MockUserService: gọi load() trước khi dùng currentUser');
    return _user!;
  }
}
