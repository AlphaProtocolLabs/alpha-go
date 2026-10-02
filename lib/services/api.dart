import 'dart:convert';

import 'package:alpha_go/models/chat_models.dart';
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
      String method, String path, [Map<String, dynamic>? body,
      Duration timeout = const Duration(seconds: 20)]) async {
    final req = http.Request(method, _u(path))
      ..headers.addAll(await _headers());
    if (body != null) req.body = jsonEncode(body);
    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(timeout));
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

  // ── Chats ────────────────────────────────────────────────────────────────

  static Future<List<ChatSummary>> chats() async {
    final data = await _send('GET', '/api/chats');
    return (data['chats'] as List)
        .map((c) => ChatSummary.fromApi(c as Map<String, dynamic>))
        .toList();
  }

  static Future<String> openDm(String memberId) async {
    final data = await _send('POST', '/api/chats', {'memberId': memberId});
    return data['id'] as String;
  }

  static Future<List<ChatMessage>> messages(String chatId, {int after = 0}) async {
    final data = await _send('GET', '/api/chats/$chatId/messages?after=$after');
    return (data['messages'] as List)
        .map((m) => ChatMessage.fromApi(m as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message. For Topsi this waits for her reply (several seconds).
  /// A 503 means Topsi is unavailable; her notice is already in the chat.
  static Future<void> sendMessage(String chatId, String body) async {
    try {
      await _send('POST', '/api/chats/$chatId/messages', {'body': body},
          const Duration(seconds: 65));
    } on ApiException catch (e) {
      if (e.status == 503) return;
      rethrow;
    }
  }

  static Future<void> sendVibe(String chatId, int amount, String? note) async {
    await _send('POST', '/api/chats/$chatId/vibe', {
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  // ── Members ──────────────────────────────────────────────────────────────

  static Future<List<Member>> searchMembers(String q) async {
    final data = await _send('GET', '/api/members?q=${Uri.encodeQueryComponent(q)}');
    return (data['members'] as List)
        .map((m) => Member.fromApi(m as Map<String, dynamic>))
        .toList();
  }

  /// Returns the member, whether I blocked them, and whether we can message.
  static Future<(Member, bool, bool)> member(String id) async {
    final data = await _send('GET', '/api/members/$id');
    return (
      Member.fromApi(data['member'] as Map<String, dynamic>),
      data['blockedByMe'] as bool? ?? false,
      data['canMessage'] as bool? ?? false,
    );
  }

  static Future<void> block(String id, bool blocked) =>
      _send('POST', '/api/members/$id/block', {'blocked': blocked});

  static Future<void> report(String id, String reason, {int? messageId}) =>
      _send('POST', '/api/members/$id/report', {
        'reason': reason,
        if (messageId != null) 'messageId': messageId,
      });

  // ── VIBE ─────────────────────────────────────────────────────────────────

  /// Withdraw to an Aptos testnet address. Returns the transaction hash.
  static Future<String?> withdraw(int amount, String address) async {
    final data = await _send('POST', '/api/vibe/withdraw',
        {'amount': amount, 'address': address}, const Duration(seconds: 65));
    return data['tx'] as String?;
  }
}
