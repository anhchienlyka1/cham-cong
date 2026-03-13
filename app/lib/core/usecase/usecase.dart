import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base use case interface.
/// [T] is the return type, [Params] is the input parameter type.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when the use case doesn't need any parameters.
class NoParams {
  const NoParams();
}
