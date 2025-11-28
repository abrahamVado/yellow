import '../../../core/storage/token_storage.dart';
import '../../../core/error/error_mapper.dart';
import '../../../domain/auth/entities/auth_token.dart';
import '../../../domain/auth/entities/user.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;
  final ErrorMapper errorMapper;

  AuthRepositoryImpl({
    required this.remote,
    required this.tokenStorage,
    required this.errorMapper,
  });

  @override
  Future<AuthToken> login({
    required String username,
    required String password,
  }) async {
    try {
      final dto = LoginRequestDto(username: username, password: password);
      final response = await remote.login(dto);

      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      await tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      return token;
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
      await tokenStorage.clear();
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final response = await remote.refreshToken(refreshToken);
      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      await tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      return token;
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    // TODO: implement user profile call and mapping.
    return null;
  }

  @override
  Future<AuthToken> loginWithGoogle({required String idToken}) async {
    try {
      final response = await remote.loginWithGoogle(idToken);
      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      await tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      return token;
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> registerWithGoogleAndPhone({
    required String idToken,
    required String phoneNumber,
  }) async {
    try {
      await remote.registerWithGoogleAndPhone(
        idToken: idToken,
        phoneNumber: phoneNumber,
      );
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> registerWithPhone({
    required String phoneNumber,
    required String role,
  }) async {
    try {
      await remote.registerWithPhone(
        phoneNumber: phoneNumber,
        role: role,
      );
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AuthToken> verifySmsCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await remote.verifySmsCode(phone: phone, code: code);
      final token = AuthToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      await tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      return token;
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }
  @override
  Future<String?> getToken() async {
    return await tokenStorage.readAccessToken();
  }
}
