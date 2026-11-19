import 'package:flutter/foundation.dart';

/// Runtime configuration for the API the app talks to.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  /// The Android emulator reaches the host machine through 10.0.2.2, while a
  /// browser on the same machine reaches it through 127.0.0.1.
  /// For a real phone on the same network, pass your machine's LAN IP:
  ///
  /// ```sh
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
  /// ```
  static AppConfig get fromEnvironment {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return AppConfig(apiBaseUrl: override);
    }
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return AppConfig(apiBaseUrl: 'http://$host:8000/api');
    }
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return AppConfig(
      apiBaseUrl: isDesktop ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api',
    );
  }
}
