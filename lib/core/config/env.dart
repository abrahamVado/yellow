class Env {
  final String baseUrl;
  final String appEnv;

  final String googleMapsApiKey;

  static const String apiUrl = 'https://api.softwaremia.com';

  Env({
    required this.baseUrl,
    required this.appEnv,
    required this.googleMapsApiKey,
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
    const googleMapsApiKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '', // Set via --dart-define=GOOGLE_MAPS_API_KEY=...
    );

    return Env(
      baseUrl: baseUrl,
      appEnv: appEnv,
      googleMapsApiKey: googleMapsApiKey,
    );
  }
}
