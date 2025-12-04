import 'package:dio/dio.dart';

import '../models/login_request_dto.dart';
import '../models/login_response_dto.dart';
import '../models/user_profile_model.dart';
import '../../../domain/auth/exceptions.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    final data = response.data!;
    return LoginResponseDto.fromJson(data);
  }

  Future<void> logout() async {
    await dio.post('/auth/logout');
  }

  Future<LoginResponseDto> refreshToken(String refreshToken) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data!;
    return LoginResponseDto.fromJson(data);
  }

  Future<LoginResponseDto> loginWithGoogle(String idToken) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      final data = response.data!;
      return LoginResponseDto.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final data = e.response?.data as Map<String, dynamic>?;
        throw UserNotFoundException(
          email: data?['email'],
          name: data?['name'],
        );
      } else if (e.response?.statusCode == 202) {
        final data = e.response?.data as Map<String, dynamic>?;
        throw PendingVerificationException(
          phone: data?['phone_number'],
        );
      }
      rethrow;
    }
  }

  /// Register user with Google + phone, backend should send SMS and return 200 OK.
  Future<void> registerWithGoogleAndPhone({
    required String idToken,
    required String phoneNumber,
  }) async {
    try {
      await dio.post('/auth/register-phone-google', data: {
        'id_token': idToken,
        'phone_number': phoneNumber,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 202) {
        throw PendingVerificationException(phone: phoneNumber);
      }
      rethrow;
    }
  }

  /// Register user with just phone number.
  Future<void> registerWithPhone({
    required String phoneNumber,
    required String role,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    await dio.post('/auth/register-phone', data: {
      'phone_number': phoneNumber,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });
  }

  /// Verify phone code and return auth tokens.
  Future<LoginResponseDto> verifySmsCode({
    required String phone,
    required String code,
    String? idToken,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verify-phone-code',
      data: {
        'phone_number': phone,
        'code': code,
        if (idToken != null) 'id_token': idToken,
      },
    );
    final data = response.data!;
    return LoginResponseDto.fromJson(data);
  }

  Future<UserProfileModel> getProfile() async {
    final response = await dio.get<Map<String, dynamic>>('/auth/me');
    final data = response.data!;
    return UserProfileModel.fromJson(data);
  }

  Future<void> updateFCMToken(String token) async {
    await dio.post('/auth/fcm-token', data: {'fcm_token': token});
  }
}
