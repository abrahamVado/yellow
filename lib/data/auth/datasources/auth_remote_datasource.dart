import 'package:dio/dio.dart';

import '../models/login_request_dto.dart';
import '../models/login_response_dto.dart';

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
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'id_token': idToken},
    );
    final data = response.data!;
    return LoginResponseDto.fromJson(data);
  }

  /// Register user with Google + phone, backend should send SMS and return 200 OK.
  Future<void> registerWithGoogleAndPhone({
    required String idToken,
    required String phoneNumber,
  }) async {
    await dio.post('/auth/register-phone-google', data: {
      'id_token': idToken,
      'phone_number': phoneNumber,
    });
  }

  /// Register user with just phone number.
  Future<void> registerWithPhone({
    required String phoneNumber,
    required String role,
  }) async {
    await dio.post('/auth/register-phone', data: {
      'phone_number': phoneNumber,
      'role': role,
    });
  }

  /// Verify phone code and return auth tokens.
  Future<LoginResponseDto> verifySmsCode({
    required String phone,
    required String code,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verify-phone-code',
      data: {
        'phone_number': phone,
        'code': code,
      },
    );
    final data = response.data!;
    return LoginResponseDto.fromJson(data);
  }
}
