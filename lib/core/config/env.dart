class Env {
  final String baseUrl;
  final String appEnv;

  Env({
    required this.baseUrl,
    required this.appEnv,
  });

  static Future<Env> load() async {
    const baseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://api.example.com',
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
