import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

class AppConfig {
  final String baseUrl;
  final String environment;

  const AppConfig({
    required this.baseUrl,
    required this.environment,
  });

  factory AppConfig.fromEnv(Env env) {
    return AppConfig(
      baseUrl: env.baseUrl,
      environment: env.appEnv,
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig not initialized');
});
