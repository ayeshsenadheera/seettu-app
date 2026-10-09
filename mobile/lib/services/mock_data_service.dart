import 'package:flutter/material.dart';
import 'api_client.dart';

class MockDataService {
  static final _api = ApiClient();

  static Future<List<Map<String, dynamic>>> getGroups() async {
    final res = await _api.get('/groups');
    return List<Map<String, dynamic>>.from(res['groups'] ?? []);
  }

  static Future<Map<String, dynamic>> getGroupDetails(String id) async {
    final res = await _api.get('/groups/$id');
    return res['group'];
  }

  static Future<void> createGroup(Map<String, dynamic> data) async {
    await _api.post('/groups', data);
  }

  static Future<void> updateGroup(String id, Map<String, dynamic> data) async {
    await _api.put('/groups/$id', data);
  }

  static Future<void> deleteGroup(String id) async {
    await _api.delete('/groups/$id');
  }

  static Future<List<Map<String, dynamic>>> getMembersForGroup(String groupId) async {
    final res = await _api.get('/groups/$groupId/members');
    return List<Map<String, dynamic>>.from(res['members'] ?? []);
  }

  static Future<Map<String, dynamic>> getMemberDetails(String groupId, String memberId) async {
    final res = await _api.get('/groups/$groupId/members/$memberId');
    return res['member'];
  }

  static Future<void> createMember(String groupId, Map<String, dynamic> data) async {
    await _api.post('/groups/$groupId/members', data);
  }

  static Future<void> updateMember(String groupId, String memberId, Map<String, dynamic> data) async {
    await _api.put('/groups/$groupId/members/$memberId', data);
  }

  static Future<void> deleteMember(String groupId, String memberId) async {
    await _api.delete('/groups/$groupId/members/$memberId');
  }
}
