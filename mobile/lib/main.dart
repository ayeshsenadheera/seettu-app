import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/loader.dart' show appRouteObserver;
import 'services/tab_state.dart';
import 'theme.dart';

import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/groups/group_details_screen.dart';
import 'screens/groups/group_form_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/members/member_details_screen.dart';
import 'screens/members/member_form_screen.dart';
import 'screens/payment_screens.dart';
import 'screens/payout_screens.dart';
import 'screens/profile_screens.dart';
import 'screens/trusted_people_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase not configured. Bypassing...');
  }
  runApp(const SeettuApp());
}

class SeettuApp extends StatelessWidget {
  const SeettuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => TabState()),
      ],
      child: MaterialApp(
        title: 'seettū',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        navigatorObservers: [appRouteObserver],
        home: const _Root(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (app.bootError != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 40, color: AppColors.red),
                const SizedBox(height: 12),
                Text(app.bootError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => context.read<AppState>().retryBoot(), child: const Text('Try again')),
              ]),
            ),
          ),
        ),
      );
    }
    return app.user == null ? const AuthFlow() : const _Tabs();
  }
}

/// Onboarding, Login and Sign Up live on their own nested Navigator. When sign-in
/// succeeds, AppState.user changes, _Root rebuilds, and this whole subtree (and its
/// stack) is torn down in favour of _Tabs — no manual "go to home" navigation needed.
class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/login':
            page = const LoginScreen();
            break;
          case '/signup':
            page = const SignUpScreen();
            break;
          default:
            page = const OnboardingScreen();
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();
  @override
  Widget build(BuildContext context) {
    final index = context.watch<TabState>().index;
    final pages = const [HomeScreen(), GroupsScreen(), PaymentDashboardScreen(), MembersScreen(), ProfileScreen()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mute,
        onTap: (i) => context.read<TabState>().go(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_outlined), activeIcon: Icon(Icons.swap_horiz), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_alt_outlined), activeIcon: Icon(Icons.person_add_alt), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  Widget page;
  final args = settings.arguments;

  switch (settings.name) {
    case '/group-form':
      page = GroupFormScreen(id: args as String?);
      break;
    case '/group-details':
      page = GroupDetailsScreen(id: args as String);
      break;
    case '/member-form':
      final m = args as Map<String, dynamic>;
      page = MemberFormScreen(groupId: m['groupId'] as String, memberId: m['memberId'] as String?);
      break;
    case '/member-details':
      final m = args as Map<String, dynamic>;
      page = MemberDetailsScreen(groupId: m['groupId'] as String, memberId: m['memberId'] as String);
      break;
    case '/record-payment':
      final m = (args as Map<String, dynamic>?) ?? {};
      page = RecordPaymentScreen(groupId: m['groupId'] as String?, memberId: m['memberId'] as String?, month: m['month'] as String?);
      break;
    case '/payment-history':
      page = const PaymentHistoryScreen();
      break;
    case '/shared-records':
      page = const SharedRecordsScreen();
      break;
    case '/missed-late':
      page = const MissedLateScreen();
      break;
    case '/payment-reminder':
      page = const PaymentReminderScreen();
      break;
    case '/payouts':
      page = const PayoutsScreen();
      break;
    case '/payout-details':
      final m = args as Map<String, dynamic>;
      page = PayoutDetailsScreen(payout: m['payout'] as Map<String, dynamic>, groupName: m['groupName'] as String);
      break;
    case '/rules':
      page = const RulesScreen();
      break;
    case '/account':
      page = const AccountScreen();
      break;
    case '/accessibility':
      page = const AccessibilityScreen();
      break;
    case '/trusted-people':
      page = const TrustedPeopleScreen();
      break;
    default:
      return null;
  }
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
