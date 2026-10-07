import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_client.dart';
import 'app_state.dart';
import 'loader.dart';

/// Loads the user's groups and resolves which one is "current" (the group picked
/// on the Payment / Members / Payouts screens), defaulting to the first group.
/// Mirrors the useCurrentGroup hook from the React Native version.
class WithCurrentGroup extends StatelessWidget {
  final Widget Function(BuildContext context, List<Map<String, dynamic>> groups, Map<String, dynamic>? group, Future<void> Function() reload) builder;
  const WithCurrentGroup({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return DataLoader<List<dynamic>>(
      load: () async => (await api.get('/groups'))['groups'] as List<dynamic>,
      builder: (context, raw, reload) {
        final groups = raw.cast<Map<String, dynamic>>();
        final appState = context.watch<AppState>();
        Map<String, dynamic>? group = groups.where((g) => g['id'] == appState.groupId).isNotEmpty
            ? groups.firstWhere((g) => g['id'] == appState.groupId)
            : (groups.isNotEmpty ? groups.first : null);

        if (group != null && group['id'] != appState.groupId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.read<AppState>().setGroupId(group!['id'] as String);
          });
        }
        return builder(context, groups, group, reload);
      },
    );
  }
}
