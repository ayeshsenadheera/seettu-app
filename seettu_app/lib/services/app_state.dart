import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

const Map<String, dynamic> defaultSettings = {
  'language': 'English',
  'textSize': 'Medium',
  'reminder': {'enabled': true, 'daysBefore': 3, 'method': 'Push'},
};

/// Holds the signed-in user's profile, settings, and which group is currently
/// selected on the Payment / Members / Payouts tabs. One instance lives for the
/// whole app (see main.dart), so every screen sees the same values.
class AppState extends ChangeNotifier {
  Map<String, dynamic>? user; // backend profile: {id, name, email, phone, role, settings}
  Map<String, dynamic> settings = defaultSettings;
  String? groupId;
  bool booting = true;
  String? bootError;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? fbUser) async {
    if (fbUser == null) {
      user = null;
      settings = defaultSettings;
      groupId = null;
      booting = false;
      notifyListeners();
      return;
    }
    try {
      final r = await api.get('/auth/me');
      user = r['user'] as Map<String, dynamic>;
      settings = (user!['settings'] as Map<String, dynamic>?) ?? defaultSettings;
      bootError = null;
    } on ApiException catch (e) {
      if (e.status == 404) {
        // Signed in to Firebase but has no profile yet (mid sign-up, or a fresh account
        // that never finished syncing). SignUpScreen handles creating the profile.
        user = null;
      } else {
        bootError = e.message;
      }
    } catch (e) {
      bootError = errMsg(e);
    }
    booting = false;
    notifyListeners();
  }

  /// Call right after Firebase sign-up, with the extra details Firebase doesn't collect.
  Future<void> completeSignUp({required String name, required String phone}) async {
    final r = await api.post('/auth/sync', {'name': name, 'phone': phone});
    user = r['user'] as Map<String, dynamic>;
    settings = (user!['settings'] as Map<String, dynamic>?) ?? defaultSettings;
    notifyListeners();
  }

  /// Retries loading the profile after a network error on boot (see the "Try again"
  /// button shown when bootError is set).
  Future<void> retryBoot() async {
    booting = true;
    bootError = null;
    notifyListeners();
    await _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  void setUser(Map<String, dynamic> u) {
    user = u;
    settings = (u['settings'] as Map<String, dynamic>?) ?? settings;
    notifyListeners();
  }

  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> patch) async {
    final r = await api.put('/settings', patch);
    settings = r['settings'] as Map<String, dynamic>;
    notifyListeners();
    return settings;
  }

  void setGroupId(String? id) {
    groupId = id;
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    user = null;
    groupId = null;
    settings = defaultSettings;
    notifyListeners();
  }

  String get reminderMethod => (settings['reminder']?['method'] as String?) ?? 'Push';
  int get reminderDays => (settings['reminder']?['daysBefore'] as num?)?.toInt() ?? 3;
  bool get reminderEnabled => (settings['reminder']?['enabled'] as bool?) ?? true;
  String get textSize => (settings['textSize'] as String?) ?? 'Medium';
  String get language => (settings['language'] as String?) ?? 'English';
}
