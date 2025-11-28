import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

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
      state = AuthState.initial();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
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
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.registerWithPhone(
        phoneNumber: phoneNumber,
        role: role,
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
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.verifySmsCode(phone: phone, code: code);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );
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
}
