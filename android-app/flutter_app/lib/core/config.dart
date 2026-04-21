class AppConfig {
  static const String schoolId = 'demo-school';

  // Override at build/run time:
  // flutter run --dart-define=API_BASE=https://<host>/v1
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue:
        'https://asia-south1-smarttime-ai-1b64f.cloudfunctions.net/api/v1',
  );
}
