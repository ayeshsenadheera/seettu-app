import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}

// A friendly message for any error thrown by ApiClient, ready to show in the UI.
String errMsg(Object e) {
  if (e is ApiException) return e.message;
  return 'Cannot reach the server. Check that it is running and your phone is on the same Wi-Fi.';
}

class ApiClient {
  final _base = Config.apiUrl;

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, v?.toString())) ?? <String, String?>{};
    q.removeWhere((k, v) => v == null);
    return Uri.parse('$_base$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> body = {};
    try { if (r.body.isNotEmpty) body = jsonDecode(r.body) as Map<String, dynamic>; } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiException(body['message']?.toString() ?? 'Something went wrong. Please try again.', status: r.statusCode);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await http.get(_uri(path, query), headers: await _headers()).timeout(const Duration(seconds: 12));
      return _decode(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(errMsg(e));
    }
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    try {
      final r = await http.post(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 12));
      return _decode(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(errMsg(e));
    }
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    try {
      final r = await http.put(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 12));
      return _decode(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(errMsg(e));
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final r = await http.delete(_uri(path), headers: await _headers()).timeout(const Duration(seconds: 12));
      return _decode(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(errMsg(e));
    }
  }
}

final api = ApiClient();
