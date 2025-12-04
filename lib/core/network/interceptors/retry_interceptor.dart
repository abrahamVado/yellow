import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;

  RetryInterceptor({
    required this.dio,
    required this.tokenStorage,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      print('RetryInterceptor: Caught 401, attempting refresh...');
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken != null) {
        print('RetryInterceptor: Refresh token found.');
        try {
          // Create a new Dio instance to avoid interceptor loops
          final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
          
          print('RetryInterceptor: Calling /auth/refresh...');
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          print('RetryInterceptor: Refresh response: ${response.statusCode}');
          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];

            print('RetryInterceptor: Saving new tokens...');
            await tokenStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Retry the original request with the new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            print('RetryInterceptor: Retrying original request...');
            final cloneReq = await dio.request(
              opts.path,
              options: Options(
                method: opts.method,
                headers: opts.headers,
                extra: opts.extra,
                responseType: opts.responseType,
                contentType: opts.contentType,
                validateStatus: opts.validateStatus,
                receiveTimeout: opts.receiveTimeout,
                sendTimeout: opts.sendTimeout,
              ),
              data: opts.data,
              queryParameters: opts.queryParameters,
            );

            return handler.resolve(cloneReq);
          }
        } catch (e) {
          print('RetryInterceptor: Refresh failed: $e');
          // Refresh failed, clear tokens
          await tokenStorage.clear();
        }
      } else {
        print('RetryInterceptor: No refresh token found.');
      }
    }
    handler.next(err);
  }
}
