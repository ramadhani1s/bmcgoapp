// Web-only upload helper using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:frontend_website_bmc/services/auth_service.dart';
import 'dart:async';

Future<String?> uploadFile(html.File file) async {
  try {
    final formData = html.FormData();
    formData.appendBlob('file', file, file.name);

    final token = await AuthService.getToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty)
      headers['Authorization'] = 'Bearer $token';

    final request = await html.HttpRequest.request(
      '${AuthService.baseUrl}/api/admin/upload',
      method: 'POST',
      sendData: formData,
      requestHeaders: headers,
    );

    if (request.status == 200 || request.status == 201) {
      final resp = request.responseText;
      if (resp != null && resp.isNotEmpty) {
        final data = jsonDecode(resp) as Map<String, dynamic>;
        return data['url'] as String?;
      }
    }
  } catch (e) {
    // ignore
  }
  return null;
}

Future<String?> pickAndUpload() async {
  final input = html.FileUploadInputElement();
  input.accept = '.png,.jpg,.jpeg';
  input.multiple = false;

  final completer = Completer<String?>();

  input.onChange.listen((_) async {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final url = await uploadFile(file);
      completer.complete(url);
    } else {
      completer.complete(null);
    }
  });

  input.click();

  return completer.future;
}
