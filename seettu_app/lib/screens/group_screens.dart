import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../services/loader.dart';
import '../services/tab_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataLoader<List<dynamic>>(
      load: () async => (await api.get('/groups'))['groups'] as List<dynamic>,
      builder: (context, groups, reload) => AppScreen(
        title: 'My Seettu Groups',
        back: false,
        onRefresh: reload,
        footer: PrimaryButton(
          title: 'Add Group',
          icon: Icons.add,
          onPressed: () => Navigator.of(context).pushNamed('/group-form'),
        ),
        children: [
          if (groups.isEmpty)
            const EmptyBox(text: 'You have no groups yet. Tap Add Group to start your first seettu.')
          else
            ...groups.cast<Map<String, dynamic>>().map((g) {
              final memberCount = (g['memberCount'] as num).toInt();
              final paid = (g['paidThisMonth'] as num).toInt();
              final pct = memberCount == 0 ? 0.0 : (paid / memberCount).clamp(0, 1).toDouble();
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => Navigator.of(context).pushNamed('/group-details', arguments: g['id']),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AppText(g['name'] as String, size: 17, weight: FontWeight.w700),
                        AppText('${g['frequency']} · $memberCount members', size: 13, color: AppColors.mute),
                      ]),
                    ),
                    AppText(rs(g['contribution'] as num?), weight: FontWeight.w800, color: AppColors.primary),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.grey, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    AppText('$paid/$memberCount members paid', size: 13, color: AppColors.mute),
                    AppText('Next collection ${fmtDate(g['nextCollection'])}', size: 13, color: AppColors.mute),
                  ]),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

class GroupFormScreen extends StatefulWidget {
  final String? id;
  const GroupFormScreen({super.key, this.id});
  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final name = TextEditingController();
  final contribution = TextEditingController();
  final memberLimit = TextEditingController();
  final startDate = TextEditingController(text: todayStr());
  final description = TextEditingController();
  String frequency = 'Monthly';
  Map<String, String> errors = {};
  bool busy = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final g = (await api.get('/groups/${widget.id}'))['group'] as Map<String, dynamic>;
      name.text = g['name'] as String;
      contribution.text = (g['contribution'] as num).toString();
      memberLimit.text = (g['memberLimit'] as num).toString();
      startDate.text = g['startDate'].toString().substring(0, 10);
      description.text = (g['description'] as String?) ?? '';
      frequency = g['frequency'] as String;
    } catch (e) {
      if (mounted) setState(() => errors = {'form': errMsg(e)});
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'Enter a group name.';
    final c = num.tryParse(contribution.text);
    if (c == null || c <= 0) e['contribution'] = 'Enter an amount more than 0.';
    final n = int.tryParse(memberLimit.text);
    if (n == null || n < 2 || n > 100) e['memberLimit'] = 'Enter a number between 2 and 100.';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(startDate.text) || DateTime.tryParse(startDate.text) == null) {
      e['startDate'] = 'Use the format YYYY-MM-DD.';
    }
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    setState(() => busy = true);
    final body = {
      'name': name.text,
      'contribution': contribution.text,
      'frequency': frequency,
      'memberLimit': memberLimit.text,
      'startDate': startDate.text,
      'description': description.text,
    };
    try {
      final r = widget.id != null ? await api.put('/groups/${widget.id}', body) : await api.post('/groups', body);
      final g = r['group'] as Map<String, dynamic>;
      if (widget.id == null && mounted) context.read<AppState>().setGroupId(g['id'] as String);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/group-details', arguments: g['id']);
      }
    } catch (err) {
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.id != null;
    return AppScreen(
      title: editing ? 'Edit Group' : 'Create Seettu Group',
      children: loading
          ? [const LoadingBox()]
          : [
              AppField(label: 'Group name', controller: name, error: errors['name'], placeholder: 'e.g. Family Seettu'),
              AppField(label: 'Contribution amount (Rs.)', controller: contribution, keyboardType: TextInputType.number, error: errors['contribution']),
              const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Payment frequency', size: 14, weight: FontWeight.w600)),
              ChipGroup<String>(
                options: const [ChipOption('Monthly', 'Monthly'), ChipOption('Weekly', 'Weekly')],
                value: frequency,
                onChanged: (v) => setState(() => frequency = v),
              ),
              AppField(label: 'Number of members', controller: memberLimit, keyboardType: TextInputType.number, error: errors['memberLimit']),
              AppField(label: 'Start date (YYYY-MM-DD)', controller: startDate, error: errors['startDate']),
              AppField(label: 'Description (optional)', controller: description, maxLines: 3),
              if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
              PrimaryButton(title: editing ? 'Save Changes' : 'Create Group', onPressed: save, loading: busy),
              PrimaryButton(title: 'Cancel', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
            ],
    );
  }
}

class GroupDetailsScreen extends StatelessWidget {
  final String id;
  const GroupDetailsScreen({super.key, required this.id});

  Future<void> _delete(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('All members and payment records in this group will be deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep group')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete group', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/groups/$id');
      if (context.mounted) {
        context.read<AppState>().setGroupId(null);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: ${errMsg(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataLoader<Map<String, dynamic>>(
      load: () async => (await api.get('/groups/$id'))['group'] as Map<String, dynamic>,
      builder: (context, g, reload) => AppScreen(
        title: 'Group Details',
        onRefresh: reload,
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.groups, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: AppText(g['name'] as String, size: 20, weight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              KVRow(label: 'Contribution', value: rs(g['contribution'] as num?)),
              KVRow(label: 'Payment frequency', value: g['frequency'] as String),
              KVRow(label: 'Total members', value: '${g['memberCount']} / ${g['memberLimit']}'),
              KVRow(label: 'Next payment', value: fmtDate(g['nextCollection'])),
              KVRow(label: 'Start date', value: fmtDate(g['startDate'])),
              if ((g['description'] as String?)?.isNotEmpty == true)
                Padding(padding: const EdgeInsets.only(top: 10), child: AppText(g['description'] as String, color: AppColors.mute)),
            ]),
          ),
          PrimaryButton(
            title: 'View Members',
            icon: Icons.people_outline,
            onPressed: () {
              context.read<AppState>().setGroupId(id);
              context.read<TabState>().go(3);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          PrimaryButton(
            title: 'Payout Schedule',
            icon: Icons.calendar_month_outlined,
            variant: ButtonVariant.outline,
            onPressed: () { context.read<AppState>().setGroupId(id); Navigator.of(context).pushNamed('/payouts'); },
          ),
          PrimaryButton(
            title: 'Rules & Guidelines',
            icon: Icons.description_outlined,
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(context).pushNamed('/rules'),
          ),
          PrimaryButton(
            title: 'Edit Group',
            icon: Icons.edit_outlined,
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(context).pushNamed('/group-form', arguments: id),
          ),
          PrimaryButton(
            title: 'Delete Group',
            icon: Icons.delete_outline,
            variant: ButtonVariant.dangerSolid,
            onPressed: () => _delete(context, g['name'] as String),
          ),
        ],
      ),
    );
  }
}
