import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/exceptions.dart';
import 'auth_state.dart';

import '../../core/services/fcm_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FCMService _fcmService;

  AuthNotifier(this._repository, this._fcmService) : super(AuthState.initial());

  Future<void> _registerFCM() async {
    try {
      print('📱 FCM: Initializing...');
      await _fcmService.initialize();
      
      print('📱 FCM: Getting token...');
      final token = await _fcmService.getToken();
      
      if (token != null) {
        print('📱 FCM: Token obtained, length: ${token.length}');
        await _repository.updateFCMToken(token);
        print('✅ FCM: Token registered successfully');
      } else {
        print('⚠️ FCM: Token is null');
      }
    } catch (e, stackTrace) {
      print('❌ FCM: Registration failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.login(username: username, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );
      // CRITICAL FIX: Await FCM registration to prevent race condition
      await _registerFCM();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.logout();
      // Delete FCM token to prevent receiving notifications for this user
      await _fcmService.deleteToken(); 
      state = AuthState.initial();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Login using Google account (ID token provided by a callback).
  Future<void> loginWithGoogle(
    Future<String?> Function() getIdToken,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final idToken = await getIdToken();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      await _repository.loginWithGoogle(idToken: idToken);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );
      // CRITICAL FIX: Await FCM registration
      await _registerFCM();
    } on UserNotFoundException {
      state = state.copyWith(
        isLoading: false,
        isUserNotFound: true,
      );
    } on PendingVerificationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        pendingVerificationPhone: e.phone,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Register user with Google + phone and trigger SMS sending.
  Future<bool> registerWithGoogleAndPhone({
    required String idToken,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerWithGoogleAndPhone(
        idToken: idToken,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  /// Register user with phone number only.
  Future<bool> registerWithPhone({
    required String phoneNumber,
    required String role,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerWithPhone(
        phoneNumber: phoneNumber,
        role: role,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  /// Verify SMS code and complete login.
  Future<bool> verifySmsCode({
    required String phone,
    required String code,
    String? idToken,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.verifySmsCode(phone: phone, code: code, idToken: idToken);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );
      // CRITICAL FIX: Await FCM registration
      await _registerFCM();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
  /// Check if user is already authenticated by reading stored tokens.
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _repository.getToken();
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );
        // Fetch profile if authenticated
        await fetchProfile();
        // CRITICAL FIX: Await FCM registration
        await _registerFCM();
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<void> fetchProfile() async {
    // Don't set global loading here to avoid full screen spinner if background fetch
    try {
      final user = await _repository.getProfile();
      state = state.copyWith(user: user);
    } catch (e) {
      // If profile fetch fails, maybe token is invalid?
      // For now just log or ignore, or set error
      print('Failed to fetch profile: $e');
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteAccount();
      // Also cleanup FCM and local state same as logout
      await _fcmService.deleteToken();
      state = AuthState.initial();
    } catch (error) {
       state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateProfile(firstName: firstName, lastName: lastName, email: email);
      // Refresh profile to update UI
      await fetchProfile();
      state = state.copyWith(isLoading: false);
    } catch (error) {
       state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }
}
