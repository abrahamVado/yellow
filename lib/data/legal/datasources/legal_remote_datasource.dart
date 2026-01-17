import 'package:dio/dio.dart';

class LegalRemoteDataSource {
  final Dio dio;

  LegalRemoteDataSource({required this.dio});

  Future<String> getTerms() async {
    final response = await dio.get<Map<String, dynamic>>('/legal/terms');
    return response.data?['content'] as String? ?? '';
  }

  Future<String> getPrivacyPolicy() async {
    final response = await dio.get<Map<String, dynamic>>('/legal/privacy');
    return response.data?['content'] as String? ?? '';
  }
}
