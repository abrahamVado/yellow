import '../entities/user.dart';
import '../entities/auth_token.dart';

abstract class AuthRepository {
  Future<AuthToken> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<AuthToken> refreshToken(String refreshToken);

  Future<User?> getCurrentUser();

  /// Login using a Google ID token obtained from google_sign_in.
  Future<AuthToken> loginWithGoogle({
    required String idToken,
  });

  /// Register user with Google ID token + phone number.
  /// Backend should send an SMS with a verification code.
  Future<void> registerWithGoogleAndPhone({
    required String idToken,
    required String phoneNumber,
  });

  /// Register user with phone number only.
  Future<void> registerWithPhone({
    required String phoneNumber,
    required String role,
    String? firstName,
    String? lastName,
    String? email,
  });

  /// Verify SMS code and obtain final auth tokens.
  Future<AuthToken> verifySmsCode({
    required String phone,
    required String code,
    String? idToken,
  });

  /// Get the stored access token.
  Future<String?> getToken();

  /// Fetch current user profile from backend.
  Future<User> getProfile();
  Future<void> updateFCMToken(String token);
  Future<void> deleteAccount();
  Future<void> updateProfile({String? firstName, String? lastName, String? email});
}
