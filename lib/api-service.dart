import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.1.101:3000';
  static final _storage = FlutterSecureStorage();

  // ---------------- AUTH ----------------
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'role', value: data['user']['role']);
      return data;
    } else {
      return null;
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  // ---------------- DOCUMENTS ----------------
  static Future<List<dynamic>> getDocuments() async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/documents');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return [];
    }
  }

  static Future<bool> createDocument(String title, String content) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/documents');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );

    return res.statusCode == 201;
  }

  // ---------------- LOGS ----------------
  static Future<List<dynamic>> getLogs() async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/logs');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> postLog(String action) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/logs');
    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );
  }

  // ---------------- NOTIFICATIONS ----------------
  static Future<List<dynamic>> getNotifications() async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/notifications');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> createNotification(
    String title,
    String message,
    String type,
  ) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/notifications');
    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'message': message, 'type': type}),
    );
  }

  // ---------------- UTILS ----------------
  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'admin';
  }
}
