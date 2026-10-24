import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'vnverse';
  static const String defaultAssistantName = 'Trợ lý Giám đốc';
  static const String coordinatorAgentId = 'coordinator';

  // ===========================================================================
  // BACKEND SERVER URL CONFIGURATION
  // Tự động thích ứng môi trường (Android Emulator -> 10.0.2.2, iOS/Desktop -> 127.0.0.1)
  // ===========================================================================
  static String get defaultApiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api/v1';
}
