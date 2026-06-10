class ApiConfig {
  // Set to true when running the app on a development device (e.g., emulator or phone
  // connected to the same Wi‑Fi network as the backend). In that case we use the local
  // backend address. When false the app will target the production Railway backend.
  static const bool useEmulator = true;

  static String get baseUrl {
    // Production backend URL (HTTPS, no port)
    const prodUrl = 'https://bmcgoapp-production.up.railway.app';
    // Development URL – adjust the IP/port if your backend runs elsewhere.
    const devUrl = 'http://10.0.2.2:8080'; // ✅ khusus emulator Android
    return useEmulator ? devUrl : prodUrl;
  }
}