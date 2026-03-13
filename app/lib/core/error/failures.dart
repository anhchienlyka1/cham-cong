import 'package:equatable/equatable.dart';

/// Failure classes for the domain layer.
/// Used with `Either<Failure, Success>` pattern.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Không có kết nối mạng'});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Phiên đăng nhập hết hạn'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
