import 'package:dio/dio.dart';

class LegalRemoteDataSource {
  final Dio dio;

  LegalRemoteDataSource({required this.dio});

  Future<String> getTerms() async {
    final response = await dio.get<Map<String, dynamic>>('/auth/legal/terms');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return data?['content'] as String? ?? '';
  }

  Future<String> getPrivacyPolicy() async {
    final response = await dio.get<Map<String, dynamic>>('/auth/legal/privacy');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return data?['content'] as String? ?? '';
  }
}
