/// App-wide configuration constants.
class AppConfig {
  AppConfig._();

  static const String appName = 'Price Ninja';
  static const String appVersion = '4.0.0';
  static const String appTagline = 'Smart Price Tracking';

  // Backend URL
  // - Android Emulator: 10.0.2.2 (maps to host machine localhost)
  // - Real device: use your machine's local IP (e.g., 192.168.x.x)
  // - Override via: flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000
  // In production, Flutter Web on Firebase (HTTPS) MUST connect to HTTPS backend.
  // Using http://10.0.2.2 as fallback on web causes immediate network layer error.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pricetrackerninja-production.up.railway.app',
  );
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://pricetrackerninja-production.up.railway.app',
  );

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration scrapeTimeout = Duration(seconds: 90);

  // Pagination
  static const int defaultPageSize = 15;

  // Animation durations
  static const Duration flipDuration = Duration(milliseconds: 600);
  static const Duration typingCharDelay = Duration(milliseconds: 50);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration glowPulse = Duration(seconds: 2);
}
