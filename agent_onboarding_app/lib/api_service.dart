import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'https://api.grahvarta.com/api';

  static Future<String> uploadPhoto(File file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/hirings/upload-photo'));
    req.files.add(await http.MultipartFile.fromPath('photo', file.path));
    final res = await req.send();
    final body = jsonDecode(await res.stream.bytesToString());
    if (res.statusCode != 200) throw body['message'] ?? 'Upload failed';
    return body['data']['url'] as String;
  }

  static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    final r = await http.post(
      Uri.parse('$_base/hirings/apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final body = jsonDecode(r.body);
    if (r.statusCode != 201) throw body['message'] ?? 'Submission failed';
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getApplicationStatus(String phone) async {
    final r = await http.get(Uri.parse('$_base/hirings/status?phone=${Uri.encodeComponent(phone)}'));
    final body = jsonDecode(r.body);
    if (r.statusCode != 200) throw body['message'] ?? 'Not found';
    return body['data'] as Map<String, dynamic>;
  }
}
