import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seettu/frontend/frontend_app.dart';

void main() {
  testWidgets('payments filter and selected member details work offline', (tester) async {
    await tester.pumpWidget(const FrontendApp());
    expect(find.text('Marcus Vance'), findsOneWidget);
    await tester.tap(find.text('Late (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Marcus Vance'), findsNothing);
    expect(find.text('Alice Cameron'), findsOneWidget);
    await tester.tap(find.text('Alice Cameron'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('PAY-18813'), findsNWidgets(2));
    expect(find.text('Late (5 days late)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payout schedule opens the selected slot and rules', (tester) async {
    await tester.pumpWidget(const FrontendApp());
    await tester.tap(find.text('Payouts').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Marcus Vance'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Marcus Vance'));
    await tester.pumpAndSettle();
    expect(find.text('Payout Details'), findsOneWidget);
    expect(find.text('#4 / 12'), findsOneWidget);
    await tester.tap(find.text('View Payout Rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penalties'));
    await tester.pumpAndSettle();
    expect(find.text('Grace period'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone layout and reminder preview work', (tester) async {
    tester.view.physicalSize = const Size(393, 742);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FrontendApp());
    await tester.tap(find.text('Notify All Members'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Reminder previews created for 3 members.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
