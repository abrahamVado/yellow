import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.readAccessToken();
    print('AuthInterceptor: Checking token for ${options.path}');
    if (token != null && token.isNotEmpty) {
      print('AuthInterceptor: Token found (length: ${token.length})');
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      print('AuthInterceptor: No token found!');
    }
    handler.next(options);
  }
}
