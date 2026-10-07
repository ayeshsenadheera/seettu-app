import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../services/loader.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _options = [
  {'key': 'payoutDate', 'label': 'My payout date', 'hint': "When it's my turn to receive"},
  {'key': 'paymentStatus', 'label': 'My payment status', 'hint': 'Paid, upcoming or late'},
  {'key': 'amount', 'label': 'Contribution amount', 'hint': 'What I pay each cycle'},
];
final _labelFor = {for (final o in _options) o['key']!: o['label']!};
const _durations = [ChipOption('7 days', 7), ChipOption('30 days', 30), ChipOption('Until I revoke it', 0)];

class TrustedPeopleScreen extends StatefulWidget {
  const TrustedPeopleScreen({super.key});
  @override
  State<TrustedPeopleScreen> createState() => _TrustedPeopleScreenState();
}

class _TrustedPeopleScreenState extends State<TrustedPeopleScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final code = TextEditingController();
  String relationship = 'Family';
  Set<String> share = {'payoutDate', 'paymentStatus'};
  int days = 30;
  Map<String, String> errors = {};
  bool busyInvite = false;
  bool busyAccept = false;

  void _toggle(String key) => setState(() => share.contains(key) ? share.remove(key) : share.add(key));

  void _shareInvite(Map<String, dynamic> p, String ownerName) {
    Share.share(
      "${p['name']}, $ownerName invited you to view their seettu payout details (view-only). "
      "Open the Seettu app, go to Profile > Privacy and enter code ${p['inviteCode']}.",
    );
  }

  Future<void> _invite(Future<void> Function() reloadMine) async {
    final ownerName = context.read<AppState>().user!['name'] as String;
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = "Enter the person's full name.";
    if (!validPhone(phone.text)) e['phone'] = 'Enter a valid number, like 0771234567 or +94771234567.';
    if (share.isEmpty) e['share'] = 'Choose at least one thing they can see.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    setState(() => busyInvite = true);
    try {
      final r = await api.post('/trusted', {
        'name': name.text, 'phone': phone.text, 'relationship': relationship, 'share': share.toList(), 'days': days,
      });
      final person = r['person'] as Map<String, dynamic>;
      name.clear();
      phone.clear();
      await reloadMine();
      if (!mounted) return;
      final wantsShare = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invite created'),
          content: Text("Send ${person['name']} the code ${person['inviteCode']}."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Share invite')),
          ],
        ),
      );
      if (wantsShare == true) _shareInvite(person, ownerName);
    } catch (err) {
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busyInvite = false);
  }

  Future<void> _revoke(Map<String, dynamic> p, Future<void> Function() reloadMine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Revoke access for ${p['name']}?'),
        content: const Text('They will lose access straight away. You can invite them again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep access')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke access', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/trusted/${p['id']}');
      await reloadMine();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not revoke: ${errMsg(e)}')));
    }
  }

  Future<void> _accept(Future<void> Function() reloadShared) async {
    setState(() { busyAccept = true; errors = {}; });
    try {
      await api.post('/trusted/accept', {'code': code.text.trim()});
      code.clear();
      await reloadShared();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access added. You can now see what they shared.')));
    } catch (err) {
      setState(() => errors = {'code': errMsg(err)});
    }
    if (mounted) setState(() => busyAccept = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Trusted people',
      children: [
        AppCard(
          background: AppColors.primaryLight,
          borderColor: AppColors.primaryLight,
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppText('View-only access, and you stay in control', weight: FontWeight.w700),
            AppText("They can't pay, edit or see other members' details. You can revoke access at any time."),
          ]),
        ),
        const SectionTitle('Invite someone'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppField(label: 'Full name', controller: name, error: errors['name'], placeholder: 'e.g. Kumari Perera'),
            AppField(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone, placeholder: '07X XXX XXXX', error: errors['phone']),
            const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Relationship', size: 14, weight: FontWeight.w600)),
            ChipGroup<String>(
              options: const [ChipOption('Family', 'Family'), ChipOption('Friend', 'Friend'), ChipOption('Other', 'Other')],
              value: relationship,
              onChanged: (v) => setState(() => relationship = v),
            ),
            const Padding(padding: EdgeInsets.only(top: 14), child: AppText('What they can see', size: 14, weight: FontWeight.w600)),
            for (var i = 0; i < _options.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: i == 0 ? Colors.transparent : AppColors.line))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText(_options[i]['label']!),
                      AppText(_options[i]['hint']!, size: 13, color: AppColors.mute),
                    ]),
                  ),
                  Switch(
                    value: share.contains(_options[i]['key']),
                    activeColor: AppColors.primary,
                    onChanged: (_) => _toggle(_options[i]['key']!),
                  ),
                ]),
              ),
            if (errors['share'] != null) AppText(errors['share']!, size: 13, color: AppColors.red),
            const AppText("Never shared: other members, your bank details and your login.", size: 13, color: AppColors.mute),
            const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Access lasts', size: 14, weight: FontWeight.w600)),
            ChipGroup<int>(options: _durations, value: days, onChanged: (v) => setState(() => days = v)),
            if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
          ]),
        ),
        DataLoader<List<dynamic>>(
          load: () async => (await api.get('/trusted'))['people'] as List<dynamic>,
          builder: (context, raw, reloadMine) {
            final mine = raw.cast<Map<String, dynamic>>();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PrimaryButton(title: 'Send invite', onPressed: () => _invite(reloadMine), loading: busyInvite),
              SectionTitle('People with access${mine.isNotEmpty ? ' (${mine.length})' : ''}'),
              if (mine.isEmpty)
                const EmptyBox(text: 'No one has access yet.')
              else
                ...mine.map((p) => AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AvatarCircle(name: p['name'] as String),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              AppText(p['name'] as String, weight: FontWeight.w700),
                              AppText('${p['relationship']} · ${p['phone']}', size: 13, color: AppColors.mute),
                              AppText('Can see: ${(p['share'] as List).map((k) => _labelFor[k] ?? k).join(', ')}', size: 13, color: AppColors.mute),
                              AppText(p['expiresAt'] != null ? 'Expires ${fmtDate(p['expiresAt'])}' : 'No expiry', size: 13, color: AppColors.mute),
                            ]),
                          ),
                          StatusTag(p['status'] as String),
                        ]),
                        if (p['status'] == 'Pending')
                          PrimaryButton(
                            title: 'Share invite code ${p['inviteCode']}',
                            variant: ButtonVariant.outline,
                            onPressed: () => _shareInvite(p, context.read<AppState>().user!['name'] as String),
                          ),
                        PrimaryButton(title: 'Revoke access', variant: ButtonVariant.dangerSolid, onPressed: () => _revoke(p, reloadMine)),
                      ]),
                    )),
            ]);
          },
        ),
        const SectionTitle('Shared with me'),
        DataLoader<List<dynamic>>(
          load: () async => (await api.get('/trusted/shared'))['shared'] as List<dynamic>,
          builder: (context, raw, reloadShared) {
            final shared = raw.cast<Map<String, dynamic>>();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppField(label: 'Enter an invite code', controller: code, keyboardType: TextInputType.number, placeholder: '6-digit code', error: errors['code']),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: code,
                    builder: (context, value, _) => PrimaryButton(
                      title: 'Add access',
                      variant: ButtonVariant.outline,
                      onPressed: value.text.trim().length < 6 ? null : () => _accept(reloadShared),
                      loading: busyAccept,
                    ),
                  ),
                ]),
              ),
              ...shared.map((s) {
                final data = s['data'] as Map<String, dynamic>;
                return AppCard(
                  margin: const EdgeInsets.only(top: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppText(s['ownerName'] as String, weight: FontWeight.w700, size: 16),
                    AppText(data['groupName'] != null ? data['groupName'] as String : 'No group details yet.', size: 13, color: AppColors.mute),
                    if (data['payoutDate'] != null)
                      Padding(padding: const EdgeInsets.only(top: 8), child: RichText(text: TextSpan(style: const TextStyle(color: AppColors.ink, fontSize: 15), children: [
                        const TextSpan(text: 'Payout date: '),
                        TextSpan(text: fmtDate(data['payoutDate']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]))),
                    if (data['paymentStatus'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(children: [const AppText('This month: '), const SizedBox(width: 6), StatusTag(data['paymentStatus'] as String)]),
                      ),
                    if (data['amount'] != null)
                      Padding(padding: const EdgeInsets.only(top: 8), child: RichText(text: TextSpan(style: const TextStyle(color: AppColors.ink, fontSize: 15), children: [
                        const TextSpan(text: 'Contribution: '),
                        TextSpan(text: rs(data['amount'] as num?), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]))),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppText('${s['expiresAt'] != null ? 'Access until ${fmtDate(s['expiresAt'])}' : 'No expiry'} · view only', size: 13, color: AppColors.mute),
                    ),
                  ]),
                );
              }),
            ]);
          },
        ),
      ],
    );
  }
}
