import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_website_bmc/services/mentor_competition_service.dart';
import 'package:frontend_website_bmc/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow real HTTP requests in Flutter tests
  HttpOverrides.global = null;

  test('Test getByType for olimpiade with real HTTP', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODEwOTg0NDMsInJvbGVfaWQiOjIsInVzZXJfaWQiOjd9.eUxBjbbtBg_dfhyZuW3TfXM9StQTjtmsOenLZ2NM50g',
      'user': '{"id":7,"username":"sabet","email":"sabet@gmail.com","role_id":2}'
    });

    final headers = await AuthService.getAuthHeaders();
    print('Generated Headers: $headers');

    print('Calling getByType...');
    try {
      final items = await MentorCompetitionService.getByType('olimpiade');
      print('Items loaded successfully. Count: ${items.length}');
      for (var item in items) {
        print('- ID: ${item.id}, Title: ${item.title}, ClassLevel: ${item.classLevel}, Duration: ${item.durationLabel}');
      }
    } catch (e, stack) {
      print('Caught Exception: $e');
      print(stack);
    }
  });
}
