import '../../../core/storage/token_storage.dart';
import '../../../core/error/error_mapper.dart';
import '../../../domain/auth/entities/auth_token.dart';
import '../../../domain/auth/entities/user.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_dto.dart';
import '../models/user_profile_model.dart';
import '../../../domain/auth/exceptions.dart';

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
      if (error is UserNotFoundException || error is PendingVerificationException) {
        rethrow;
      }
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
      if (error is PendingVerificationException) {
        rethrow;
      }
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> registerWithPhone({
    required String phoneNumber,
    required String role,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      await remote.registerWithPhone(
        phoneNumber: phoneNumber,
        role: role,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AuthToken> verifySmsCode({
    required String phone,
    required String code,
    String? idToken,
  }) async {
    try {
      final response = await remote.verifySmsCode(phone: phone, code: code, idToken: idToken);
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

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      return await remote.getProfile();
    } catch (e, stackTrace) {
      throw errorMapper.map(e, stackTrace);
    }
  }

  @override
  Future<void> updateFCMToken(String token) async {
    try {
      if (token.isEmpty) return;
      await remote.updateFCMToken(token);
    } catch (e) {
      // Ignored for now
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await remote.deleteAccount();
      // Clear local storage after successful deletion
      await tokenStorage.clear();
    } catch (e, stackTrace) {
      throw errorMapper.map(e, stackTrace);
    }
  }

  @override
  Future<void> updateProfile({String? firstName, String? lastName, String? email}) async {
    try {
      await remote.updateProfile(firstName: firstName, lastName: lastName, email: email);
    } catch (e, stackTrace) {
      throw errorMapper.map(e, stackTrace);
    }
  }
}
