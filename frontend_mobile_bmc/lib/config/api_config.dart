class ApiConfig {
  static const bool useEmulator = true;

  static String get baseUrl {
    if (useEmulator) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://172.27.69.110:8080';
  }
}