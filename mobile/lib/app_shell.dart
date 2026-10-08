// 5-tab shell (Home, Groups, Payment, Members, Profile) from the Figma prototype.
// Yeshanii's files in lib/frontend are NOT modified. Her screens are reused:
//   Profile tab        -> her ConnectedProfile (+ a "Trusted people" button)
//   /missed-late       -> her ConnectedOutstanding
//   /payouts           -> her ConnectedPayouts
//   /rules             -> her ConnectedRules
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'frontend/connected_frontend.dart' as her;
import 'frontend/six_screen_repository.dart' show SixScreenRepository;
import 'screens/group_screens.dart';
import 'screens/home_screen.dart';
import 'screens/member_screens.dart';
import 'screens/payment_screens.dart';
import 'services/app_state.dart';
import 'services/tab_state.dart';

final SixScreenRepository _repo = SixScreenRepository();

const Color _green = Color(0xFF128A4B);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = context.watch<TabState>();
    return Scaffold(
      body: IndexedStack(
        index: tabs.index,
        children: const [
          HomeScreen(),
          GroupsScreen(),
          PaymentDashboardScreen(),
          MembersScreen(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabs.index,
        onTap: tabs.go,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Yeshanii's Profile screen, unchanged, with one extra button underneath
/// that opens the Trusted people screen.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: her.ConnectedProfile(
              key: const ValueKey('profile'),
              repository: _repo,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Trusted people'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context).pushNamed('/trusted-people'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps one of her screens so it can open as a normal page (with a back
/// button). It loads her group list the same way her own shell does.
class _HerPage extends StatelessWidget {
  final String title;
  final Widget Function(String groupId, bool canManage) pageBuilder;
  const _HerPage({required this.title, required this.pageBuilder});

  @override
  Widget build(BuildContext context) {
    final wanted = context.read<AppState>().groupId;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: her.LiveData(
          load: _repo.groups,
          builder: (data, reload) {
            final groups = her.rows(data['groups']);
            if (groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No savings pools yet. Contact your organizer.'),
                    TextButton(onPressed: reload, child: const Text('Refresh pools')),
                  ],
                ),
              );
            }
            final group = groups.firstWhere(
              (g) => g['id'] == wanted,
              orElse: () => groups.first,
            );
            return pageBuilder(group['id'] as String, group['canManage'] == true);
          },
        ),
      ),
    );
  }
}

/// Use in main.dart:  onGenerateRoute: (s) => herRoutes(s) ?? _onGenerateRoute(s)
Route<dynamic>? herRoutes(RouteSettings settings) {
  switch (settings.name) {
    case '/missed-late':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => _HerPage(
          title: 'Payments',
          pageBuilder: (id, canManage) => her.ConnectedOutstanding(
            key: ValueKey('payments-$id'),
            repository: _repo,
            groupId: id,
            canManage: canManage,
          ),
        ),
      );
    case '/payouts':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => _HerPage(
          title: 'Payouts',
          pageBuilder: (id, canManage) => her.ConnectedPayouts(
            key: ValueKey('payouts-$id'),
            repository: _repo,
            groupId: id,
          ),
        ),
      );
    case '/rules':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => _HerPage(
          title: 'Rules',
          pageBuilder: (id, canManage) => her.ConnectedRules(
            key: ValueKey('rules-$id'),
            repository: _repo,
            groupId: id,
          ),
        ),
      );
  }
  return null;
}
