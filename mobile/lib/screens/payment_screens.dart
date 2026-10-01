import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../services/current_group.dart';
import '../services/loader.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: AppText(label, weight: FontWeight.w600)),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.mute),
          ]),
        ),
      );
}

class PaymentDashboardScreen extends StatelessWidget {
  const PaymentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WithCurrentGroup(
      builder: (context, groups, group, reload) => AppScreen(
        title: 'Payment',
        back: false,
        onRefresh: reload,
        children: [
          GroupPickerBar(groups: groups, group: group, onSelect: (id) => context.read<AppState>().setGroupId(id)),
          if (group != null)
            DataLoader<Map<String, dynamic>>(
              load: () async => api.get('/payments/summary', query: {'groupId': group['id']}),
              watch: [group['id']],
              builder: (context, sm, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Payment Summary'),
                AppCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const AppText('Monthly Amount', size: 12, color: AppColors.mute),
                        AppText(rs(sm['monthlyAmount'] as num?), weight: FontWeight.w700),
                      ]),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const AppText('Next Due Date', size: 12, color: AppColors.mute),
                        AppText(fmtDate(sm['nextDue']), weight: FontWeight.w700),
                      ]),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const AppText('My Status', size: 12, color: AppColors.mute),
                        const SizedBox(height: 4),
                        StatusTag(sm['myStatus'] as String),
                      ]),
                    ),
                  ]),
                ),
                const SectionTitle('Current Payment'),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppText(monthLabel(sm['month'] as String), weight: FontWeight.w800, size: 17),
                    KVRow(label: 'Amount', value: rs(sm['monthlyAmount'] as num?)),
                    KVRow(label: 'Due Date', value: fmtDate(sm['dueDate'])),
                    KVRow(label: 'Status', value: sm['myStatus'] as String),
                    PrimaryButton(
                      title: 'Record Payment',
                      onPressed: () => Navigator.of(context).pushNamed('/record-payment', arguments: {
                        'groupId': group['id'],
                        'memberId': sm['myMemberId'],
                        'month': sm['month'],
                      }),
                    ),
                  ]),
                ),
                const SectionTitle('Quick Actions'),
                _Action(icon: Icons.history, label: 'My Payment History', onTap: () => Navigator.of(context).pushNamed('/payment-history')),
                _Action(icon: Icons.people_outline, label: 'Shared Payment Records', onTap: () => Navigator.of(context).pushNamed('/shared-records')),
                _Action(icon: Icons.error_outline, label: 'Missed / Late Payments', onTap: () => Navigator.of(context).pushNamed('/missed-late')),
                _Action(icon: Icons.notifications_outlined, label: 'Payment Reminder', onTap: () => Navigator.of(context).pushNamed('/payment-reminder')),
              ]),
            ),
        ],
      ),
    );
  }
}

class RecordPaymentScreen extends StatefulWidget {
  final String? groupId;
  final String? memberId;
  final String? month;
  const RecordPaymentScreen({super.key, this.groupId, this.memberId, this.month});
  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  String? memberId;
  final amount = TextEditingController();
  late final TextEditingController month;
  final date = TextEditingController(text: todayStr());
  String method = 'Cash';
  final reference = TextEditingController();
  Map<String, String> errors = {};
  bool busy = false;

  @override
  void initState() {
    super.initState();
    memberId = widget.memberId;
    month = TextEditingController(text: widget.month ?? thisMonthKey());
  }

  String? get groupId => widget.groupId ?? context.read<AppState>().groupId;

  Future<void> save() async {
    final e = <String, String>{};
    if (memberId == null) e['member'] = 'Choose a member.';
    if (amount.text.isNotEmpty && (num.tryParse(amount.text) == null || num.parse(amount.text) <= 0)) e['amount'] = 'Amount must be more than 0.';
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month.text)) e['month'] = 'Use the format YYYY-MM.';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date.text) || DateTime.tryParse(date.text) == null) e['date'] = 'Use the format YYYY-MM-DD.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    setState(() => busy = true);
    try {
      await api.post('/payments', {
        'groupId': groupId,
        'memberId': memberId,
        if (amount.text.isNotEmpty) 'amount': amount.text,
        'month': month.text,
        'date': date.text,
        'method': method,
        'reference': reference.text,
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment recorded'),
          content: const Text('The payment was saved.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final gid = groupId;
    if (gid == null) {
      return const AppScreen(title: 'Record Payment', children: [EmptyBox(text: 'Choose a group first from the Payment tab.')]);
    }
    return DataLoader<Map<String, dynamic>>(
      load: () async => api.get('/groups/$gid/members'),
      builder: (context, data, _) {
        final group = data['group'] as Map<String, dynamic>;
        final members = (data['members'] as List).cast<Map<String, dynamic>>();
        return AppScreen(
          title: 'Record Payment',
          children: [
            AppText(group['name'] as String, color: AppColors.mute),
            const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Member', size: 14, weight: FontWeight.w600)),
            ChipGroup<String?>(
              options: members.map((m) => ChipOption<String?>(m['name'] as String, m['id'] as String)).toList(),
              value: memberId,
              onChanged: (v) => setState(() => memberId = v),
            ),
            if (errors['member'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: AppText(errors['member']!, size: 13, color: AppColors.red)),
            AppField(
              label: 'Amount (Rs.) - leave empty for ${rs(group['contribution'] as num?)}',
              controller: amount,
              keyboardType: TextInputType.number,
              error: errors['amount'],
              placeholder: (group['contribution'] as num).toString(),
            ),
            AppField(label: 'Payment month (YYYY-MM)', controller: month, error: errors['month']),
            AppField(label: 'Payment date (YYYY-MM-DD)', controller: date, error: errors['date']),
            const Padding(padding: EdgeInsets.only(top: 14, bottom: 6), child: AppText('Payment method', size: 14, weight: FontWeight.w600)),
            ChipGroup<String>(
              options: const [ChipOption('Cash', 'Cash'), ChipOption('Bank Transfer', 'Bank Transfer'), ChipOption('Other', 'Other')],
              value: method,
              onChanged: (v) => setState(() => method = v),
            ),
            AppField(label: 'Reference / note (optional)', controller: reference),
            if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
            PrimaryButton(title: 'Record Payment', onPressed: save, loading: busy),
            PrimaryButton(title: 'Cancel', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
          ],
        );
      },
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return WithCurrentGroup(
      builder: (context, groups, group, reload) => AppScreen(
        title: 'My Payment History',
        onRefresh: reload,
        children: [
          GroupPickerBar(groups: groups, group: group, onSelect: (id) => context.read<AppState>().setGroupId(id)),
          if (group != null)
            DataLoader<Map<String, dynamic>>(
              load: () async => api.get('/payments/history', query: {'groupId': group['id']}),
              watch: [group['id']],
              builder: (context, data, _) {
                final payments = (data['payments'] as List).cast<Map<String, dynamic>>();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AppCard(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const AppText('Total Paid', size: 12, color: AppColors.mute),
                            AppText(rs(data['totalPaid'] as num?), size: 20, weight: FontWeight.w800, color: AppColors.primary),
                          ]),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const AppText('Payments', size: 12, color: AppColors.mute),
                            AppText('${data['count']}', size: 20, weight: FontWeight.w800),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SectionTitle('Payment History'),
                  if (payments.isEmpty)
                    const EmptyBox(text: 'No payments recorded yet.')
                  else
                    ...payments.map((x) => AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                AppText(x['memberName'] as String, weight: FontWeight.w700),
                                AppText('${monthLabel(x['month'] as String)} · paid ${fmtDate(x['date'])} · ${x['method']}', size: 13, color: AppColors.mute),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              AppText(rs(x['amount'] as num?), weight: FontWeight.w700),
                              const SizedBox(height: 4),
                              const StatusTag('Paid'),
                            ]),
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

class SharedRecordsScreen extends StatefulWidget {
  const SharedRecordsScreen({super.key});
  @override
  State<SharedRecordsScreen> createState() => _SharedRecordsScreenState();
}

class _SharedRecordsScreenState extends State<SharedRecordsScreen> {
  String month = thisMonthKey();

  @override
  Widget build(BuildContext context) {
    return WithCurrentGroup(
      builder: (context, groups, group, reload) => AppScreen(
        title: 'Shared Payment Records',
        onRefresh: reload,
        children: [
          GroupPickerBar(groups: groups, group: group, onSelect: (id) => context.read<AppState>().setGroupId(id)),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() => month = shiftMonth(month, -1)), icon: const Icon(Icons.chevron_left)),
              AppText(monthLabel(month), size: 18, weight: FontWeight.w800),
              IconButton(onPressed: () => setState(() => month = shiftMonth(month, 1)), icon: const Icon(Icons.chevron_right)),
            ]),
          ),
          if (group != null)
            DataLoader<Map<String, dynamic>>(
              load: () async => api.get('/payments/shared', query: {'groupId': group['id'], 'month': month}),
              watch: [group['id'], month],
              builder: (context, data, _) {
                final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
                final summary = data['summary'] as Map<String, dynamic>;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppCard(
                    child: Row(children: [
                      for (final e in [['Paid', summary['paid']], ['Pending', summary['pending']], ['Late', summary['late']], ['Missed', summary['missed']]])
                        Expanded(
                          child: Column(children: [
                            AppText('${e[1]}', size: 20, weight: FontWeight.w800),
                            AppText(e[0] as String, size: 12, color: AppColors.mute),
                          ]),
                        ),
                    ]),
                  ),
                  const SectionTitle('Members'),
                  ...rows.map((r) => AppCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              AppText(r['name'] as String, weight: FontWeight.w700),
                              AppText(rs(r['amount'] as num?), size: 13, color: AppColors.mute),
                            ]),
                          ),
                          StatusTag(r['status'] as String),
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

class MissedLateScreen extends StatefulWidget {
  const MissedLateScreen({super.key});
  @override
  State<MissedLateScreen> createState() => _MissedLateScreenState();
}

class _MissedLateScreenState extends State<MissedLateScreen> {
  String filter = 'All';
  bool busy = false;

  Future<void> _notify(List<Map<String, dynamic>> items, Future<void> Function() reload) async {
    setState(() => busy = true);
    try {
      int sent = 0;
      for (final it in items) {
        final r = await api.post('/payments/notify', {'groupId': it['groupId'], 'memberId': it['memberId'], 'month': it['month']});
        sent += (r['sent'] as num).toInt();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$sent reminder${sent == 1 ? '' : 's'} sent.')));
        await reload();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send: ${errMsg(e)}')));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return DataLoader<Map<String, dynamic>>(
      load: () async => api.get('/payments/outstanding'),
      builder: (context, data, reload) {
        final all = (data['items'] as List).cast<Map<String, dynamic>>();
        final items = filter == 'All' ? all : all.where((i) => i['status'] == filter).toList();
        return AppScreen(
          title: 'Missed / Late Payments',
          onRefresh: reload,
          children: [
            ChipGroup<String>(
              options: const [ChipOption('All', 'All'), ChipOption('Missed', 'Missed'), ChipOption('Late', 'Late')],
              value: filter,
              onChanged: (v) => setState(() => filter = v),
            ),
            if (items.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 16), child: EmptyBox(text: 'Nothing outstanding here. Everyone is up to date.'))
            else ...[
              ...items.map((i) => AppCard(
                    margin: const EdgeInsets.only(top: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            AppText(i['memberName'] as String, weight: FontWeight.w700),
                            AppText('${i['groupName']} · ${monthLabel(i['month'] as String)}', size: 13, color: AppColors.mute),
                            AppText('Due ${fmtDate(i['dueDate'])} · ${i['daysOverdue']} days overdue', size: 13, color: AppColors.mute),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          AppText(rs(i['amount'] as num?), weight: FontWeight.w700),
                          const SizedBox(height: 4),
                          StatusTag(i['status'] as String),
                        ]),
                      ]),
                      Row(children: [
                        Expanded(
                          child: PrimaryButton(title: 'Notify', variant: ButtonVariant.outline, onPressed: busy ? null : () => _notify([i], reload)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            title: 'Record payment',
                            onPressed: busy
                                ? null
                                : () => Navigator.of(context).pushNamed('/record-payment', arguments: {
                                      'groupId': i['groupId'],
                                      'memberId': i['memberId'],
                                      'month': i['month'],
                                    }),
                          ),
                        ),
                      ]),
                    ]),
                  )),
              PrimaryButton(title: 'Notify all (${items.length})', onPressed: () => _notify(items, reload), loading: busy),
            ],
          ],
        );
      },
    );
  }
}

class PaymentReminderScreen extends StatefulWidget {
  const PaymentReminderScreen({super.key});
  @override
  State<PaymentReminderScreen> createState() => _PaymentReminderScreenState();
}

class _PaymentReminderScreenState extends State<PaymentReminderScreen> {
  late bool enabled;
  late int days;
  late String method;
  bool busy = false;
  bool initialized = false;

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await context.read<AppState>().saveSettings({
        'reminder': {'enabled': enabled, 'daysBefore': days, 'method': method},
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your reminder settings were saved.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: ${errMsg(e)}')));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      final s = context.read<AppState>();
      enabled = s.reminderEnabled;
      days = s.reminderDays;
      method = s.reminderMethod;
      initialized = true;
    }
    return DataLoader<Map<String, dynamic>>(
      load: () async => api.get('/dashboard'),
      builder: (context, d, _) {
        final nextUp = d['nextUp'] as Map<String, dynamic>?;
        return AppScreen(
          title: 'Payment Reminder',
          children: [
            if (nextUp != null)
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppText('UPCOMING PAYMENT', size: 12, weight: FontWeight.w700, color: AppColors.primary),
                  const SizedBox(height: 4),
                  AppText(rs(nextUp['amount'] as num?), size: 22, weight: FontWeight.w800),
                  AppText('${nextUp['groupName']} · due ${fmtDate(nextUp['dueDate'])}', color: AppColors.mute),
                ]),
              ),
            const SectionTitle('Reminder Setting'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      AppText('Remind me before each payment', weight: FontWeight.w700),
                      AppText('You can turn this off any time.', size: 13, color: AppColors.mute),
                    ]),
                  ),
                  Switch(value: enabled, activeColor: AppColors.primary, onChanged: (v) => setState(() => enabled = v)),
                ]),
                if (enabled) ...[
                  const Padding(padding: EdgeInsets.only(top: 16, bottom: 6), child: AppText('Remind me', size: 14, weight: FontWeight.w600)),
                  ChipGroup<int>(
                    options: const [
                      ChipOption('1 day before', 1),
                      ChipOption('2 days before', 2),
                      ChipOption('3 days before', 3),
                      ChipOption('1 week before', 7),
                    ],
                    value: days,
                    onChanged: (v) => setState(() => days = v),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 16, bottom: 6), child: AppText('Notify me via', size: 14, weight: FontWeight.w600)),
                  ChipGroup<String>(
                    options: const [ChipOption('Push', 'Push'), ChipOption('SMS', 'SMS'), ChipOption('WhatsApp', 'WhatsApp')],
                    value: method,
                    onChanged: (v) => setState(() => method = v),
                  ),
                ],
              ]),
            ),
            PrimaryButton(title: 'Save Reminder', onPressed: save, loading: busy),
          ],
        );
      },
    );
  }
}
