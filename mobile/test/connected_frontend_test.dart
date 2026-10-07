import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seettu/frontend/connected_frontend.dart';
import 'package:seettu/frontend/six_screen_repository.dart';
import 'package:seettu/services/api_client.dart';

class TestApi extends ApiClient {
  final calls = <String>[];
  bool failGroups = false;
  final profile = <String, dynamic>{'name': 'Marcus Vance', 'email': 'marcus@example.com', 'phone': '0771234567', 'status': 'Active', 'role': 'Organizer', 'settings': <String, dynamic>{'textSize': 'Medium', 'sharePayoutUpdates': false, 'reminder': {'enabled': true}}};
  Map<String, dynamic> get group => {'id': 'g1', 'name': 'Community Seettu', 'canManage': true, 'memberCount': 3, 'memberLimit': 3};
  Map<String, dynamic> get slot => {'memberId': 'm1', 'name': 'Marcus Vance', 'position': 1, 'date': '2026-10-15T00:00:00Z', 'amount': 75000, 'status': 'Current', 'reference': null, 'method': 'Bank Transfer', 'paidAt': null};
  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    calls.add('GET $path');
    if (path == '/ui/groups') {
      if (failGroups) { failGroups = false; throw ApiException('Connection unavailable'); }
      return {'groups': [group]};
    }
    if (path == '/ui/profile') return {'user': profile};
    if (path.endsWith('/outstanding')) return {'group': group, 'totalOverdue': 25000, 'overdueMembers': 1, 'averageDaysOverdue': 14, 'missed': 1, 'late': 0, 'items': [{'memberId': 'm1', 'memberName': 'Marcus Vance', 'status': 'Missed', 'month': '2026-09', 'dueDate': '2026-09-22T00:00:00Z', 'amount': 25000, 'daysOverdue': 14}]};
    if (path.contains('/payments/')) {
      expect(query?['month'], '2026-09');
      return {'group': group, 'member': {'name': 'Marcus Vance', 'phone': '0771234567'}, 'pendingAmount': 25000, 'cycle': '2026-09', 'daysOverdue': 14, 'reference': 'DB-001', 'assignedAmount': 25000, 'paidAmount': 0, 'dueDate': '2026-09-22T00:00:00Z', 'status': 'Missed', 'latePenalty': 350, 'communicationHistory': []};
    }
    if (path.endsWith('/payouts')) return {'group': group, 'potAmount': 75000, 'completed': 0, 'total': 1, 'progress': 0, 'current': slot, 'payouts': [slot]};
    if (path.contains('/payouts/')) return {'group': group, 'total': 1, 'payout': slot};
    if (path.endsWith('/rules')) return {'group': group, 'version': '1.0', 'potAmount': 75000, 'sections': {'General': [{'title': 'Contribution schedule', 'text': 'Pay the agreed monthly contribution.'}], 'Rules': [], 'Penalties': [{'title': 'Grace period', 'text': 'Seven days.'}]}};
    throw ApiException('Unexpected test URL: $path');
  }
  @override
  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    calls.add('PUT $path');
    if (path == '/ui/profile') { profile.addAll(body!); return {'user': profile}; }
    if (path == '/ui/profile/settings') return {'settings': body};
    throw ApiException('Unexpected test URL');
  }
}

void main() {
  testWidgets('six live screens read backend data and preserve navigation', (tester) async {
    tester.view.physicalSize = const Size(393, 742);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = TestApi();
    await tester.pumpWidget(MaterialApp(home: ConnectedFrontendShell(repository: SixScreenRepository(client: api))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Marcus Vance'), 150, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Marcus Vance'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('DB-001'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payouts').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Marcus Vance'), 150, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Marcus Vance'));
    await tester.pumpAndSettle();
    expect(find.text('Payout Details'), findsOneWidget);
    await tester.tap(find.text('View Payout Rules'));
    await tester.pumpAndSettle();
    expect(find.text('Rules & Guidelines'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Yeshani Wijesundara');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Yeshani Wijesundara'), findsOneWidget);
    expect(api.calls, contains('PUT /ui/profile'));
    expect(api.calls, contains('GET /ui/groups/g1/payments/m1'));
    expect(api.calls, contains('GET /ui/groups/g1/payouts/m1'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed backend requests offer retry', (tester) async {
    final api = TestApi()..failGroups = true;
    await tester.pumpWidget(MaterialApp(home: ConnectedFrontendShell(repository: SixScreenRepository(client: api))));
    await tester.pumpAndSettle();
    expect(find.text('Connection unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Missed / Late payments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
