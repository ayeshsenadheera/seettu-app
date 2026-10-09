import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://192.168.1.25:5000/api/groups');
  final res = await http.get(url, headers: {'Content-Type': 'application/json'});
  final data = jsonDecode(res.body);
  final groups = List<Map<String, dynamic>>.from(data['groups'] ?? []);
  print(groups[0]);
}
