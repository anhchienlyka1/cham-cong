part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

/// Event cập nhật ca làm việc cho user trong state
class AuthShiftUpdated extends AuthEvent {
  final String shift;

  const AuthShiftUpdated({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// Event cập nhật ngày vào công ty cho user trong state
class AuthJoinDateUpdated extends AuthEvent {
  final DateTime joinDate;

  const AuthJoinDateUpdated({required this.joinDate});

  @override
  List<Object?> get props => [joinDate];
}
