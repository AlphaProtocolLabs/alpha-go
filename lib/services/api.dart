import 'dart:convert';

import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/models/user_model.dart';
import 'package:alpha_go/services/secure_store.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

/// Client for go.alphaprotocol.network. The web guide and the app share one account.
class Api {
  static Uri _u(String path) => Uri.parse('${Constants.apiBase}$path');

  static Future<Map<String, String>> _headers() async {
    final token = await SecureStore.token();
    return {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _send(
      String method, String path, [Map<String, dynamic>? body]) async {
    final req = http.Request(method, _u(path))
      ..headers.addAll(await _headers());
    if (body != null) req.body = jsonEncode(body);
    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 20)));
    } catch (_) {
      throw ApiException('Could not reach Alpha GO. Check your connection.');
    }
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode >= 400) {
      throw ApiException(
          data['error'] as String? ?? 'Something went wrong (${res.statusCode}).',
          res.statusCode);
    }
    return data;
  }

  static Future<void> _keepToken(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    if (token == null) throw ApiException('Sign-in did not return a session.');
    await SecureStore.saveToken(token);
  }

  static Future<void> login(String email, String password) async {
    await _keepToken(await _send(
        'POST', '/api/auth/login', {'email': email, 'password': password}));
  }

  static Future<void> join(
      {required String email,
      required String name,
      required String password,
      String? ref}) async {
    await _keepToken(await _send('POST', '/api/auth/join', {
      'email': email,
      'name': name,
      'password': password,
      'role': 'Attending TOKEN2049',
      if (ref != null && ref.isNotEmpty) 'ref': ref,
    }));
  }

  static Future<void> logout() => SecureStore.clearToken();

  /// Null when not signed in or the session has expired.
  static Future<Account?> me() async {
    if (await SecureStore.token() == null) return null;
    final data = await _send('GET', '/api/me');
    if (data['user'] == null) {
      await SecureStore.clearToken();
      return null;
    }
    return Account.fromApi(data);
  }

  /// Send only the fields that change. An empty string clears a field.
  static Future<void> updateProfile(Map<String, String> fields) async {
    await _send('PATCH', '/api/me', fields);
  }

  static Future<List<EventModel>> events() async {
    final data = await _send('GET', '/api/events');
    return (data['events'] as List)
        .map((e) => EventModel.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(String eventId, bool saved) async {
    await _send('POST', '/api/save', {'eventId': eventId, 'saved': saved});
  }

  /// Returns the VIBE earned.
  static Future<int> checkIn(String eventId, double lat, double lng) async {
    final data = await _send(
        'POST', '/api/checkin', {'eventId': eventId, 'lat': lat, 'lng': lng});
    return (data['earned'] as num?)?.toInt() ?? 0;
  }
}
