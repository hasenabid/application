class ApiConstants {
  // 🛠️ FIXED: Replaced emulator alias 10.0.2.2 with your true local network IP address
  // Note: Make sure this is the exact same IP address you put in your ESP32 code!
  static const String baseUrl = 'http://192.168.1.111:8081';// ⚠️ Swap with your actual IPv4!

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}
