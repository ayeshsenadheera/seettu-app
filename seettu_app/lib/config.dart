import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// The API runs on your computer. Change apiHost to your computer's IP address so a real phone
// on the same Wi-Fi can reach it (find it with `ipconfig`). 10.0.2.2 is the special address the
// Android emulator uses to reach "localhost" on your computer; iOS Simulator can use localhost.
class Config {
  static const String apiHost = 'CHANGE_ME'; // e.g. '192.168.1.10' — leave as-is to auto-pick for emulators
  static const int apiPort = 5000;

  static String get apiUrl {
    if (apiHost != 'CHANGE_ME') return 'http://$apiHost:$apiPort/api';
    if (kIsWeb) return 'http://localhost:$apiPort/api';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$apiPort/api';
    return 'http://localhost:$apiPort/api';
  }
}
