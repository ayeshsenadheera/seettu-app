import '../services/api_client.dart';

/// All live six-screen requests use the existing Firebase ID-token API client.
class SixScreenRepository {
  final ApiClient client;
  SixScreenRepository({ApiClient? client}) : client = client ?? api;

  Future<Map<String, dynamic>> groups() => client.get('/ui/groups');
  Future<Map<String, dynamic>> outstanding(String groupId) =>
      client.get('/ui/groups/$groupId/outstanding');
  Future<Map<String, dynamic>> payment(
          String groupId, String memberId, String month) =>
      client.get('/ui/groups/$groupId/payments/$memberId',
          query: {'month': month});
  Future<Map<String, dynamic>> reminders(String groupId) =>
      client.post('/ui/groups/$groupId/reminders', {});
  Future<Map<String, dynamic>> payouts(String groupId) =>
      client.get('/ui/groups/$groupId/payouts');
  Future<Map<String, dynamic>> payout(String groupId, String memberId) =>
      client.get('/ui/groups/$groupId/payouts/$memberId');
  Future<Map<String, dynamic>> rules(String groupId) =>
      client.get('/ui/groups/$groupId/rules');
  Future<Map<String, dynamic>> profile() => client.get('/ui/profile');
  Future<Map<String, dynamic>> saveProfile(String name, String phone) =>
      client.put('/ui/profile', {'name': name, 'phone': phone});
  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> patch) =>
      client.put('/ui/profile/settings', patch);
}
