import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../services/current_group.dart';
import '../services/loader.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WithCurrentGroup(
      builder: (context, groups, group, reload) => AppScreen(
        title: 'Member List',
        back: false,
        onRefresh: reload,
        footer: group == null
            ? null
            : PrimaryButton(
                title: 'Add Member',
                icon: Icons.person_add_alt,
                onPressed: () => Navigator.of(context).pushNamed('/member-form', arguments: {'groupId': group['id']}),
              ),
        children: [
          GroupPickerBar(groups: groups, group: group, onSelect: (id) => context.read<AppState>().setGroupId(id)),
          if (group != null)
            DataLoader<Map<String, dynamic>>(
              load: () async => api.get('/groups/${group['id']}/members'),
              watch: [group['id']],
              builder: (context, data, _) {
                final members = (data['members'] as List).cast<Map<String, dynamic>>();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle('Members (${members.length}/${group['memberLimit']})'),
                  if (members.isEmpty)
                    const EmptyBox(text: 'No members yet.')
                  else
                    ...members.map((m) => AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => Navigator.of(context).pushNamed('/member-details', arguments: {'groupId': group['id'], 'memberId': m['id']}),
                          child: Row(children: [
                            AvatarCircle(name: m['name'] as String),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                AppText(m['name'] as String, weight: FontWeight.w700),
                                AppText('${m['status']} · Position #${m['position']}', size: 13, color: AppColors.mute),
                              ]),
                            ),
                            if (m['nextPayout'] == true) const StatusTag('Next Payout') else const Icon(Icons.chevron_right, color: AppColors.mute),
                          ]),
                        )),
                ]);
              },
            ),
        ],
      ),
    );
  }
}

class MemberFormScreen extends StatefulWidget {
  final String groupId;
  final String? memberId;
  const MemberFormScreen({super.key, required this.groupId, this.memberId});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  String status = 'Active';
  Map<String, String> errors = {};
  bool busy = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final m = (await api.get('/groups/${widget.groupId}/members/${widget.memberId}'))['member'] as Map<String, dynamic>;
      name.text = m['name'] as String;
      phone.text = m['phone'] as String;
      email.text = (m['email'] as String?) ?? '';
      status = m['status'] as String;
    } catch (e) {
      if (mounted) setState(() => errors = {'form': errMsg(e)});
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = "Enter the member's full name.";
    if (!validPhone(phone.text)) e['phone'] = 'Enter a valid number, like 0771234567.';
    if (email.text.isNotEmpty && !validEmail(email.text)) e['email'] = 'Enter a valid email address.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    setState(() => busy = true);
    final body = {'name': name.text, 'phone': phone.text, 'email': email.text, 'status': status};
    try {
      final path = '/groups/${widget.groupId}/members${widget.memberId != null ? '/${widget.memberId}' : ''}';
      if (widget.memberId != null) {
        await api.put(path, body);
      } else {
        await api.post(path, body);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.memberId != null;
    return AppScreen(
      title: editing ? 'Edit Member' : 'Add Member',
      children: loading
          ? [const LoadingBox()]
          : [
              AppField(label: 'Full name', controller: name, error: errors['name']),
              AppField(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone, placeholder: '07X XXX XXXX', error: errors['phone']),
              AppField(label: 'Email (optional)', controller: email, keyboardType: TextInputType.emailAddress, error: errors['email']),
              if (editing) ...[
                const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Status', size: 14, weight: FontWeight.w600)),
                ChipGroup<String>(
                  options: const [ChipOption('Active', 'Active'), ChipOption('Inactive', 'Inactive')],
                  value: status,
                  onChanged: (v) => setState(() => status = v),
                ),
              ],
              if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
              PrimaryButton(title: editing ? 'Save Changes' : 'Add Member', onPressed: save, loading: busy),
              PrimaryButton(title: 'Cancel', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
            ],
    );
  }
}

class MemberDetailsScreen extends StatelessWidget {
  final String groupId;
  final String memberId;
  const MemberDetailsScreen({super.key, required this.groupId, required this.memberId});

  Future<void> _remove(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('They will be removed from this group. Their past payments stay in the history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep member')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove member', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete('/groups/$groupId/members/$memberId');
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove: ${errMsg(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataLoader<Map<String, dynamic>>(
      load: () async => (await api.get('/groups/$groupId/members/$memberId'))['member'] as Map<String, dynamic>,
      builder: (context, m, reload) => AppScreen(
        title: 'Member Details',
        onRefresh: reload,
        children: [
          Center(
            child: Column(children: [
              AvatarCircle(name: m['name'] as String, size: 84),
              const SizedBox(height: 10),
              AppText(m['name'] as String, size: 22, weight: FontWeight.w800),
              const SizedBox(height: 6),
              StatusTag(m['status'] as String),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              KVRow(label: 'Phone number', value: m['phone'] as String),
              KVRow(label: 'Email', value: (m['email'] as String?)?.isNotEmpty == true ? m['email'] as String : '-'),
              KVRow(label: 'Payout position', value: '#${m['position']}'),
              KVRow(label: 'Payout date', value: fmtDate(m['payoutDate'])),
            ]),
          ),
          PrimaryButton(
            title: 'Edit Member',
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.of(context).pushNamed('/member-form', arguments: {'groupId': groupId, 'memberId': memberId}),
          ),
          PrimaryButton(title: 'Remove Member', icon: Icons.delete_outline, variant: ButtonVariant.dangerSolid, onPressed: () => _remove(context, m['name'] as String)),
        ],
      ),
    );
  }
}
