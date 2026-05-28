/// API Configuration - centralized configuration for backend connectivity.
/// 
/// Automatically selects the appropriate backend URL based on:
/// - Platform (Android, iOS, Web, Desktop)
/// - Target (Emulator/Simulator vs Physical Device)
/// 
/// To connect to a specific backend:
/// 1. Android Emulator: Uses 10.0.2.2 (emulator → host)
/// 2. Physical Device: Set your machine's IP or domain
/// 3. iOS Simulator: Uses localhost
/// 4. Web: Uses current host or configured domain
/// 5. Desktop (Windows/macOS/Linux): Uses localhost

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Toggle debug logging for API calls
const bool apiDebugMode = true;

/// API Configuration management
class ApiConfig {
  /// Default timeout for API requests (seconds)
  static const int requestTimeoutSeconds = 30;

  /// Default timeout for uploads (seconds) - longer for large files
  static const int uploadTimeoutSeconds = 60;

  /// Get the appropriate backend base URL based on platform and environment
  static String getBaseUrl({String? override}) {
    // If override is provided, use it (useful for testing/CI)
    if (override != null && override.isNotEmpty) {
      return override;
    }

    // Check for environment variable on startup
    const String envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Check web platform first (works across all platforms)
    if (kIsWeb) {
      // Web defaults to the current origin
      // This works when flutter web is served from same domain as API
      // For remote API, use your server URL
      return 'http://localhost:8000'; // Change to your API domain
    }

    // Platform-specific defaults for native platforms
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to reference host machine
      // For physical device, replace with your machine's IP or domain
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      // For physical device, replace with your machine's IP or domain
      return 'http://localhost:8000';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms use localhost by default
      return 'http://localhost:8000';
    }

    // Fallback
    return 'http://localhost:8000';
  }

  /// Production base URL - set this to your production backend
  static const String productionUrl = 'https://api.insighthub.example.com';

  /// Development base URL with local override capability
  static String get baseUrl {
    // Use environment-based override if available
    return getBaseUrl();
  }

  /// Staging URL for testing
  static const String stagingUrl = 'https://staging-api.insighthub.example.com';
}

/// Helper to log API debug info if debug mode is enabled
void debugLog(String message) {
  if (apiDebugMode) {
    print('[API] $message');
  }
}
