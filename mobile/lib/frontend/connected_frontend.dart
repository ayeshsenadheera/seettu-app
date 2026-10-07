import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import 'frontend_app.dart';
import 'six_screen_repository.dart';

String money(dynamic value) =>
    'Rs. ${NumberFormat('#,##0.00').format((value as num?) ?? 0)}';
String calendar(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Not recorded'
      : DateFormat('MMM d, yyyy').format(date.toLocal());
}

List<Map<String, dynamic>> rows(dynamic value) => (value as List? ?? [])
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();

typedef DataBuilder = Widget Function(
    Map<String, dynamic> data, VoidCallback reload);

class LiveData extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() load;
  final DataBuilder builder;
  const LiveData({super.key, required this.load, required this.builder});
  @override
  State<LiveData> createState() => _LiveDataState();
}

class _LiveDataState extends State<LiveData> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void reload() {
    final next = widget.load();
    setState(() { future = next; });
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off, color: muted),
                      const SizedBox(height: 12),
                      Text(errMsg(snapshot.error!),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: reload, child: const Text('Try again'))
                    ])));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: emerald));
          }
          return widget.builder(snapshot.data!, reload);
        },
      );
}

class ConnectedFrontendShell extends StatefulWidget {
  final SixScreenRepository? repository;
  const ConnectedFrontendShell({super.key, this.repository});
  @override
  State<ConnectedFrontendShell> createState() => _ConnectedFrontendShellState();
}

class _ConnectedFrontendShellState extends State<ConnectedFrontendShell> {
  late final SixScreenRepository repository =
      widget.repository ?? SixScreenRepository();
  int selected = 0;
  String? groupId;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: LiveData(
                load: repository.groups,
                builder: (data, reload) {
                  final groups = rows(data['groups']);
                  if (groups.isEmpty) {
                    if (selected == 2) {
                      return ConnectedProfile(repository: repository);
                    }
                    return Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'No savings pools yet. Contact your organizer.'),
                      TextButton(
                          onPressed: reload, child: const Text('Refresh pools'))
                    ]));
                  }
                  if (!groups.any((group) => group['id'] == groupId)) {
                    groupId = groups.first['id'] as String;
                  }
                  final group =
                      groups.firstWhere((item) => item['id'] == groupId);
                  final id = groupId!;
                  final pages = [
                    ConnectedOutstanding(
                        key: ValueKey('payments-$id'),
                        repository: repository,
                        groupId: id,
                        canManage: group['canManage'] == true),
                    ConnectedPayouts(
                        key: ValueKey('payouts-$id'),
                        repository: repository,
                        groupId: id),
                    ConnectedProfile(
                        key: const ValueKey('profile'), repository: repository),
                    ConnectedRules(
                        key: ValueKey('rules-$id'),
                        repository: repository,
                        groupId: id),
                  ];
                  return Column(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: DropdownButton<String>(
                            isExpanded: true,
                            value: id,
                            items: groups
                                .map((group) => DropdownMenuItem(
                                    value: group['id'] as String,
                                    child: Text(group['name'] as String)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => groupId = value))),
                    Expanded(
                        child: IndexedStack(index: selected, children: pages))
                  ]);
                })),
        bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (value) => setState(() => selected = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined), label: 'Payments'),
              NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Payouts'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
              NavigationDestination(
                  icon: Icon(Icons.shield_outlined), label: 'Rules')
            ]),
      );
}

class ConnectedOutstanding extends StatefulWidget {
  final SixScreenRepository repository;
  final String groupId;
  final bool canManage;
  const ConnectedOutstanding(
      {super.key,
      required this.repository,
      required this.groupId,
      required this.canManage});
  @override
  State<ConnectedOutstanding> createState() => _ConnectedOutstandingState();
}

class _ConnectedOutstandingState extends State<ConnectedOutstanding> {
  String filter = 'All';
  bool sending = false;
  Future<void> remind(VoidCallback reload) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Record payment reminders?'),
                content: const Text(
                    'Save reminders for outstanding contributions. SMS and push delivery are not yet connected.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Record reminders'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => sending = true);
    try {
      final result = await widget.repository.reminders(widget.groupId);
      if (mounted) {
        feedback(context, '${result['recorded']} reminders recorded.');
        reload();
      }
    } catch (error) {
      if (mounted) feedback(context, errMsg(error));
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) => LiveData(
      load: () => widget.repository.outstanding(widget.groupId),
      builder: (data, reload) {
        final items = rows(data['items']);
        return PageFrame(
            title: 'Missed / Late payments',
            subtitle: data['group']['name'] as String,
            trailing: IconButton(
                tooltip: 'Refresh payments',
                onPressed: reload,
                icon: const Icon(Icons.refresh)),
            footer: widget.canManage && items.isNotEmpty
                ? FilledButton.icon(
                    onPressed: sending ? null : () => remind(reload),
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(sending ? 'Saving…' : 'Notify All Members'))
                : null,
            children: [
              HeroCard(
                  label: 'Total overdue pool',
                  amount: money(data['totalOverdue']),
                  caption:
                      '${data['overdueMembers']} members overdue · Average delay: ${data['averageDaysOverdue']} days'),
              SegmentedButton<String>(
                  expandedInsets: EdgeInsets.zero,
                  style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12)),
                  segments: [
                    ButtonSegment(
                        value: 'All', label: Text('All (${items.length})')),
                    ButtonSegment(
                        value: 'Missed',
                        label: Text('Missed (${data['missed']})')),
                    ButtonSegment(
                        value: 'Late', label: Text('Late (${data['late']})'))
                  ],
                  selected: {filter},
                  onSelectionChanged: (value) =>
                      setState(() => filter = value.first)),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const Surface(child: Text('All contributions are up to date.')),
              if (items.isNotEmpty &&
                  !items.any(
                      (item) => filter == 'All' || item['status'] == filter))
                const Surface(child: Text('No payments with this status.')),
              for (final item in items
                  .where((item) => filter == 'All' || item['status'] == filter))
                Surface(
                    onTap: () => openPage(
                        context,
                        ConnectedPaymentDetail(
                            repository: widget.repository,
                            groupId: widget.groupId,
                            memberId: item['memberId'] as String,
                            month: item['month'] as String)),
                    child: Column(children: [
                      Row(children: [
                        const CircleAvatar(
                            backgroundColor: mint,
                            child: Icon(Icons.person_outline, color: emerald)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(item['memberName'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700))),
                        Badge(item['status'] as String,
                            color: statusColor(item['status'] as String))
                      ]),
                      const SizedBox(height: 12),
                      DetailRow(
                          'Cycle ${item['month']} · Due ${calendar(item['dueDate'])}',
                          money(item['amount'])),
                      DetailRow('Overdue', '${item['daysOverdue']} days')
                    ])),
            ]);
      });
}

class ConnectedPaymentDetail extends StatelessWidget {
  final SixScreenRepository repository;
  final String groupId, memberId, month;
  const ConnectedPaymentDetail(
      {super.key,
      required this.repository,
      required this.groupId,
      required this.memberId,
      required this.month});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: LiveData(
          load: () => repository.payment(groupId, memberId, month),
          builder: (data, reload) => PageFrame(
                  title: 'Payment Details',
                  subtitle: 'Record & collection ledger',
                  trailing: IconButton(
                      tooltip: 'Refresh payment',
                      onPressed: reload,
                      icon: const Icon(Icons.refresh)),
                  children: [
                    HeroCard(
                        label: 'Total amount due',
                        amount: money(data['pendingAmount']),
                        caption: 'Contribution cycle ${data['cycle']}',
                        tag: '${data['daysOverdue']} DAYS OVERDUE'),
                    Surface(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(data['member']['name'] as String,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          DetailRow(
                              'Contact', data['member']['phone'] as String)
                        ])),
                    const SectionLabel('Transaction specifications'),
                    Surface(
                        child: Column(children: [
                      DetailRow(
                          'Record reference', data['reference'] as String),
                      DetailRow(
                          'Assigned amount', money(data['assignedAmount'])),
                      DetailRow('Already paid', money(data['paidAmount'])),
                      DetailRow('Due date', calendar(data['dueDate'])),
                      DetailRow('Payment status', data['status'] as String),
                      DetailRow('Late penalty', money(data['latePenalty']))
                    ])),
                    const SectionLabel('Communication history'),
                    if (rows(data['communicationHistory']).isEmpty)
                      const Surface(
                          child: Text(
                              'No reminders recorded for this contribution.')),
                    for (final item in rows(data['communicationHistory']))
                      Surface(
                          child: HistoryEntry(
                              icon: Icons.notifications_outlined,
                              title: item['status'] as String,
                              caption: item['message'] as String,
                              date: calendar(item['date']))),
                  ])));
}

class ConnectedPayouts extends StatelessWidget {
  final SixScreenRepository repository;
  final String groupId;
  const ConnectedPayouts(
      {super.key, required this.repository, required this.groupId});
  @override
  Widget build(BuildContext context) => LiveData(
      load: () => repository.payouts(groupId),
      builder: (data, reload) => PageFrame(
              title: 'Payouts',
              subtitle: data['group']['name'] as String,
              trailing: IconButton(
                  tooltip: 'Refresh payouts',
                  onPressed: reload,
                  icon: const Icon(Icons.refresh)),
              footer: FilledButton(
                  onPressed: () => openPage(context,
                      ConnectedRules(repository: repository, groupId: groupId)),
                  child: const Text('View Rules')),
              children: [
                HeroCard(
                    label: 'Cycle progress',
                    amount: money(data['potAmount']),
                    caption:
                        '${data['completed']} / ${data['total']} payouts recorded as paid',
                    children: [
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                          value: (data['progress'] as num).toDouble(),
                          backgroundColor: mint,
                          color: const Color(0xFF98E5B8)),
                      const SizedBox(height: 12),
                      Text(data['current'] == null
                          ? 'All payouts completed'
                          : 'Current turn: ${data['current']['name']}')
                    ]),
                const SectionLabel('Distribution schedule'),
                if (rows(data['payouts']).isEmpty)
                  const Surface(child: Text('No active payout slots yet.')),
                for (final payout in rows(data['payouts']))
                  Surface(
                      border: payout['status'] == 'Current' ? emerald : null,
                      onTap: () => openPage(
                          context,
                          ConnectedPayoutDetail(
                              repository: repository,
                              groupId: groupId,
                              memberId: payout['memberId'] as String)),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 17,
                            backgroundColor: mint,
                            child: Text('${payout['position']}',
                                style: const TextStyle(color: emerald))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(payout['name'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(calendar(payout['date']),
                                  style: const TextStyle(
                                      color: muted, fontSize: 12))
                            ])),
                        Badge(payout['status'] as String)
                      ])),
              ]));
}

class ConnectedPayoutDetail extends StatelessWidget {
  final SixScreenRepository repository;
  final String groupId, memberId;
  const ConnectedPayoutDetail(
      {super.key,
      required this.repository,
      required this.groupId,
      required this.memberId});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: LiveData(
          load: () => repository.payout(groupId, memberId),
          builder: (data, reload) {
            final payout = data['payout'] as Map<String, dynamic>;
            return PageFrame(
                title: 'Payout Details',
                subtitle: data['group']['name'] as String,
                footer: OutlinedButton(
                    onPressed: () => openPage(
                        context,
                        ConnectedRules(
                            repository: repository, groupId: groupId)),
                    child: const Text('View Payout Rules')),
                children: [
                  HeroCard(
                      label: '${payout['status']} payout',
                      amount: money(payout['amount']),
                      caption:
                          'Slot #${payout['position']} of ${data['total']}'),
                  Surface(
                      child: Column(children: [
                    DetailRow('Member', payout['name'] as String),
                    DetailRow('Position',
                        '#${payout['position']} / ${data['total']}'),
                    DetailRow('Payout date', calendar(payout['date'])),
                    DetailRow('Method', payout['method'] as String),
                    DetailRow('Reference',
                        payout['reference'] as String? ?? 'Not recorded'),
                    DetailRow('Status', payout['status'] as String),
                    if (payout['paidAt'] != null)
                      DetailRow('Recorded paid', calendar(payout['paidAt']))
                  ])),
                  const Surface(
                      child: Text(
                          'Payout records track disbursement status. Transfers are handled outside the app.',
                          style: TextStyle(fontSize: 12, color: muted)))
                ]);
          }));
}

class ConnectedRules extends StatefulWidget {
  final SixScreenRepository repository;
  final String groupId;
  const ConnectedRules(
      {super.key, required this.repository, required this.groupId});
  @override
  State<ConnectedRules> createState() => _ConnectedRulesState();
}

class _ConnectedRulesState extends State<ConnectedRules> {
  String tab = 'General';
  @override
  Widget build(BuildContext context) => Scaffold(
      body: LiveData(
          load: () => widget.repository.rules(widget.groupId),
          builder: (data, reload) => PageFrame(
                  title: 'Rules & Guidelines',
                  subtitle: 'Seettū Governance v${data['version']}',
                  trailing: IconButton(
                      tooltip: 'Refresh rules',
                      onPressed: reload,
                      icon: const Icon(Icons.refresh)),
                  children: [
                    HeroCard(
                        label: 'Chit pool agreement',
                        amount: money(data['potAmount']),
                        caption:
                            '${data['group']['memberCount']} members · ${data['group']['memberLimit']} cycles',
                        tag: 'Protected'),
                    SegmentedButton<String>(
                        expandedInsets: EdgeInsets.zero,
                        style: SegmentedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 12)),
                        segments: const [
                          ButtonSegment(
                              value: 'General', label: Text('General')),
                          ButtonSegment(value: 'Rules', label: Text('Rules')),
                          ButtonSegment(
                              value: 'Penalties', label: Text('Penalties'))
                        ],
                        selected: {tab},
                        onSelectionChanged: (value) =>
                            setState(() => tab = value.first)),
                    const SizedBox(height: 18),
                    for (final rule in rows(data['sections'][tab]))
                      RuleCard(
                          icon: Icons.description_outlined,
                          title: rule['title'] as String,
                          badge: tab,
                          children: [
                            Text(rule['text'] as String,
                                style:
                                    const TextStyle(color: muted, height: 1.6))
                          ])
                  ])));
}

class ConnectedProfile extends StatelessWidget {
  final SixScreenRepository repository;
  const ConnectedProfile({super.key, required this.repository});

  Future<void> edit(BuildContext context, Map<String, dynamic> user,
      VoidCallback reload) async {
    final name = TextEditingController(text: user['name'] as String);
    final phone = TextEditingController(text: user['phone'] as String);
    final form = GlobalKey<FormState>();
    bool busy = false;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Account details'),
                    content: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextFormField(
                              controller: name,
                              decoration:
                                  const InputDecoration(labelText: 'Full name'),
                              validator: (value) =>
                                  (value ?? '').trim().length < 2
                                      ? 'Enter your full name'
                                      : null),
                          TextFormField(
                              controller: phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Phone number'),
                              validator: (value) =>
                                  RegExp(r'^(?:0|\+94|94)7\d{8}$')
                                          .hasMatch(value ?? '')
                                      ? null
                                      : 'Enter a Sri Lankan mobile number'),
                          const SizedBox(height: 12),
                          Text(user['email'] as String,
                              style:
                                  const TextStyle(fontSize: 12, color: muted))
                        ])),
                    actions: [
                      TextButton(
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  if (!form.currentState!.validate()) return;
                                  update(() => busy = true);
                                  try {
                                    await repository.saveProfile(
                                        name.text.trim(), phone.text.trim());
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      reload();
                                    }
                                  } catch (error) {
                                    if (ctx.mounted) {
                                      feedback(ctx, errMsg(error));
                                      update(() => busy = false);
                                    }
                                  }
                                },
                          child: Text(busy ? 'Saving…' : 'Save'))
                    ])));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    phone.dispose();
  }

  Future<void> preference(BuildContext context, String title, String key,
      dynamic value, VoidCallback reload) async {
    bool enabled = key == 'textSize' ? value == 'Large' : value == true;
    bool busy = false;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: Text(title),
                    content: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            Text(key == 'textSize' ? 'Use larger text' : title),
                        value: enabled,
                        onChanged: busy
                            ? null
                            : (value) => update(() => enabled = value)),
                    actions: [
                      TextButton(
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  update(() => busy = true);
                                  try {
                                    await repository.saveSettings({
                                      key: key == 'textSize'
                                          ? (enabled ? 'Large' : 'Medium')
                                          : enabled
                                    });
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      reload();
                                    }
                                  } catch (error) {
                                    if (ctx.mounted) {
                                      feedback(ctx, errMsg(error));
                                      update(() => busy = false);
                                    }
                                  }
                                },
                          child: Text(busy ? 'Saving…' : 'Save'))
                    ])));
  }

  @override
  Widget build(BuildContext context) => LiveData(
      load: repository.profile,
      builder: (data, reload) {
        final user = data['user'] as Map<String, dynamic>;
        final settings = user['settings'] as Map<String, dynamic>;
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings['textSize'] == 'Large'
                    ? 1.2
                    : settings['textSize'] == 'Extra Large'
                        ? 1.3
                        : settings['textSize'] == 'Small'
                            ? 0.9
                            : 1)),
            child: PageFrame(
                title: 'Profile',
                subtitle: 'Account & preferences',
                trailing: IconButton(
                    tooltip: 'Edit account',
                    onPressed: () => edit(context, user, reload),
                    icon: const Icon(Icons.edit_outlined)),
                children: [
                  Surface(
                      child: SizedBox(
                          width: double.infinity,
                          child: Column(children: [
                            const CircleAvatar(
                                radius: 38,
                                backgroundColor: mint,
                                child: Icon(Icons.person,
                                    size: 55, color: emerald)),
                            const SizedBox(height: 12),
                            Text(user['name'] as String,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            Text(user['email'] as String,
                                style: const TextStyle(
                                    color: muted, fontSize: 12)),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              Badge(user['status'] as String),
                              Badge(user['role'] as String)
                            ])
                          ]))),
                  const SectionLabel('System settings & controls'),
                  SettingsTile(
                      number: '01',
                      title: 'ACCOUNT',
                      subtitle: 'Personal details and contact number',
                      onTap: () => edit(context, user, reload)),
                  SettingsTile(
                      number: '02',
                      title: 'SECURITY',
                      subtitle: 'Request a password reset email',
                      onTap: () async {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: user['email'] as String);
                          if (context.mounted) {
                            feedback(
                                context, 'Password reset email requested.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            feedback(context,
                                'Could not request a password reset. Try again.');
                          }
                        }
                      }),
                  SettingsTile(
                      number: '03',
                      title: 'PRIVACY',
                      subtitle: 'Share payout updates with trusted people',
                      onTap: () => preference(
                          context,
                          'Share payout updates',
                          'sharePayoutUpdates',
                          settings['sharePayoutUpdates'],
                          reload)),
                  SettingsTile(
                      number: '04',
                      title: 'NOTIFICATION',
                      subtitle: 'Payment reminder preference',
                      tag: settings['reminder']['enabled'] == true
                          ? 'ON'
                          : 'OFF',
                      onTap: () => preference(
                          context,
                          'Payment reminders',
                          'notificationsEnabled',
                          settings['reminder']['enabled'],
                          reload)),
                  SettingsTile(
                      number: '05',
                      title: 'ACCESSIBILITY',
                      subtitle: 'Display size',
                      onTap: () => preference(context, 'Accessibility',
                          'textSize', settings['textSize'], reload)),
                  OutlinedButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'))
                ]));
      });
}
