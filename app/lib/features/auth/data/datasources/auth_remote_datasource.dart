import '../../../../config/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

/// Remote data source for auth API calls.
abstract class AuthRemoteDataSource {
  Future<({UserModel user, TokenModel token})> login({
    required String email,
    required String password,
  });

  Future<({UserModel user, TokenModel token})> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<({UserModel user, TokenModel token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        token: TokenModel.fromJson(data['token'] as Map<String, dynamic>),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<({UserModel user, TokenModel token})> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        token: TokenModel.fromJson(data['token'] as Map<String, dynamic>),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
