/// API configuration for the application
class ApiConfig {
  /// Current environment - change this to switch between environments
  static const Environment environment = Environment.development;

  /// Base URL for the API
  ///
  /// For development:
  /// - Android Emulator: Use 10.0.2.2 to access host machine's localhost
  /// - iOS Simulator: Use localhost or 127.0.0.1
  /// - Physical Device: Use your computer's local IP address (e.g., 192.168.1.x)
  ///
  /// For production: Use your deployed backend URL
  static String get baseUrl => _getBaseUrl();

  /// Get the appropriate base URL based on the environment
  static String _getBaseUrl() {
    switch (environment) {
      case Environment.development:
        // For Android emulator, use 10.0.2.2
        // For iOS simulator or web, use localhost
        // For physical device, replace with your computer's IP
        return 'https://568306b77fbf.ngrok-free.app';

      case Environment.staging:
        return 'https://568306b77fbf.ngrok-free.app';

      case Environment.production:
        return 'https://568306b77fbf.ngrok-free.app';
    }
  }

  /// API endpoints
  static const String auth = '/auth';
  static const String user = '/user';
  static const String plan = '/plan';
  static const String workout = '/workout';
  static const String analytics = '/analytics';
  static const String health = '/health';

  /// Full endpoint URLs
  static String get authUrl => '$baseUrl$auth';
  static String get userUrl => '$baseUrl$user';
  static String get planUrl => '$baseUrl$plan';
  static String get workoutUrl => '$baseUrl$workout';
  static String get analyticsUrl => '$baseUrl$analytics';
  static String get healthUrl => '$baseUrl$health';

  /// Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Environment enum
enum Environment { development, staging, production }
