import '../../domain/auth/entities/user.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;
  final bool isUserNotFound;
  final String? pendingVerificationPhone;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.user,
    this.errorMessage,
    this.isUserNotFound = false,
    this.pendingVerificationPhone,
  });

  factory AuthState.initial() {
    return const AuthState(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      errorMessage: null,
      isUserNotFound: false,
      pendingVerificationPhone: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
    bool? isUserNotFound,
    String? pendingVerificationPhone,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isUserNotFound: isUserNotFound ?? this.isUserNotFound,
      pendingVerificationPhone: pendingVerificationPhone ?? this.pendingVerificationPhone,
    );
  }
}
