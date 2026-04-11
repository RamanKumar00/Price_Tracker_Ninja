/// App-wide configuration constants.
class AppConfig {
  AppConfig._();

  static const String appName = 'Price Ninja';
  static const String appVersion = '4.0.0';
  static const String appTagline = 'Smart Price Tracking';

  // Backend
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 90);
  static const Duration scrapeTimeout = Duration(seconds: 120);

  // Pagination
  static const int defaultPageSize = 15;

  // Animation durations
  static const Duration flipDuration = Duration(milliseconds: 600);
  static const Duration typingCharDelay = Duration(milliseconds: 50);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration glowPulse = Duration(seconds: 2);
}
