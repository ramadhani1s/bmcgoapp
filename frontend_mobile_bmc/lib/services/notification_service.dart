import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/config/api_config.dart';

class NotificationService {
  static Future<void> saveTokenToBackend(int userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      print("FCM TOKEN:");
      print(token);

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/save-fcm-token"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "user_id": userId,
          "fcm_token": token,
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
    } catch (e) {
      print("ERROR SAVE TOKEN: $e");
    }
  }
}