class Env {
  final String baseUrl;
  final String appEnv;

  static const String apiUrl = 'https://api.softwaremia.com';

  Env({
    required this.baseUrl,
    required this.appEnv,
  });

  static Future<Env> load() async {
    const baseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://api.softwaremia.com',
    );
    const appEnv = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );

    return Env(
      baseUrl: baseUrl,
      appEnv: appEnv,
    );
  }
}
