import 'package:flutter/material.dart';

const emerald = Color(0xFF108548);
const ink = Color(0xFF182538);
const muted = Color(0xFF748399);
const canvas = Color(0xFFF6F8FB);
const mint = Color(0xFFEAF9F1);

/// A self-contained frontend: no Firebase initialization or network requests.
class FrontendApp extends StatelessWidget {
  const FrontendApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'seettū',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: emerald, primary: emerald),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: ink, fontSize: 14),
            bodySmall: TextStyle(color: muted, fontSize: 12),
          ),
          appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, centerTitle: true),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ),
        home: const FrontendShell(),
      );
}

class FrontendShell extends StatefulWidget {
  const FrontendShell({super.key});
  @override
  State<FrontendShell> createState() => _FrontendShellState();
}

class _FrontendShellState extends State<FrontendShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: selected, children: const [OutstandingPage(), PayoutPage(), ProfilePage(), RulesPage()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (value) => setState(() => selected = value),
          backgroundColor: Colors.white,
          indicatorColor: mint,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: emerald), label: 'Payments'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: emerald), label: 'Payouts'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: emerald), label: 'Profile'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield, color: emerald), label: 'Rules'),
          ],
        ),
      );
}

void openPage(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

void feedback(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

class PageFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final Widget? trailing;
  const PageFrame({super.key, required this.title, required this.subtitle, required this.children, this.footer, this.trailing});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          leading: Navigator.of(context).canPop() ? IconButton(tooltip: 'Back', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.chevron_left)) : const Icon(Icons.savings_outlined, color: emerald),
          title: Column(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 10, color: muted))]),
          actions: [if (trailing != null) trailing!, const SizedBox(width: 12)],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: children),
          ),
        ),
        bottomNavigationBar: footer == null ? null : SafeArea(
          child: Align(heightFactor: 1, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 12), child: footer))),
        ),
      );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color? border;
  final VoidCallback? onTap;
  const Surface({super.key, required this.child, this.border, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border ?? const Color(0xFFE8EDF3), width: border == null ? 1 : 2)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child)),
        ),
      );
}

class Badge extends StatelessWidget {
  final String label;
  final Color color;
  const Badge(this.label, {super.key, this.color = emerald});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withAlpha(45))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 12), child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: muted)));
}

class HeroCard extends StatelessWidget {
  final String label;
  final String amount;
  final String caption;
  final String tag;
  final List<Widget> children;
  const HeroCard({super.key, required this.label, required this.amount, required this.caption, this.tag = '', this.children = const []});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: emerald,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: emerald.withAlpha(82), offset: const Offset(0, 12), blurRadius: 28, spreadRadius: -6)],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.1))), if (tag.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text(tag, style: const TextStyle(fontSize: 10)))]),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: Text(amount, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800))), const Icon(Icons.trending_up, color: Color(0xFF8CDAB6), size: 42)]),
            const SizedBox(height: 8),
            Text(caption, style: const TextStyle(color: Color(0xFFD2F1E1), fontSize: 12, height: 1.5)),
            ...children,
          ]),
        ),
      );
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const DetailRow(this.label, this.value, {super.key, this.color = ink});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 12))), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)))]),
      );
}

class MemberPayment {
  final String name;
  final String initials;
  final String status;
  final int days;
  final String reference;
  const MemberPayment(this.name, this.initials, this.status, this.days, this.reference);
}

const demoPayments = [
  MemberPayment('Marcus Vance', 'MV', 'Missed', 14, 'PAY-18812'),
  MemberPayment('Alice Cameron', 'AC', 'Late', 5, 'PAY-18813'),
  MemberPayment('Kiara Jaxson', 'KJ', 'Missed', 12, 'PAY-18814'),
];

Color statusColor(String status) => status == 'Missed' ? const Color(0xFFE54865) : const Color(0xFFB57A18);

class OutstandingPage extends StatefulWidget {
  const OutstandingPage({super.key});
  @override
  State<OutstandingPage> createState() => _OutstandingPageState();
}

class _OutstandingPageState extends State<OutstandingPage> {
  String filter = 'All';
  final Set<String> reminders = {};

  Future<void> notifyMembers() async {
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Notify outstanding members?'),
      content: const Text('Preview a reminder for Marcus, Alice and Kiara about their pending contributions. No messages are sent in this frontend demo.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Preview reminders'))],
    ));
    if (result != true || !mounted) return;
    setState(() => reminders.addAll(demoPayments.map((p) => p.reference)));
    feedback(context, 'Reminder previews created for 3 members.');
  }

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Missed / Late payments', subtitle: 'Auto-tracked overdue dues', trailing: const Badge('3 Pending', color: Color(0xFFE54865)),
        footer: FilledButton.icon(onPressed: notifyMembers, icon: const Icon(Icons.notifications_outlined, size: 18), label: const Text('Notify All Members')),
        children: [
          const HeroCard(label: 'Total overdue pool', amount: 'Rs. 75,000', caption: '3 members overdue  •  Average delay: 10 days', tag: 'Default risk  +4.6%'),
          SegmentedButton<String>(segments: const [ButtonSegment(value: 'All', label: Text('All (3)')), ButtonSegment(value: 'Missed', label: Text('Missed (2)')), ButtonSegment(value: 'Late', label: Text('Late (1)'))], selected: {filter}, onSelectionChanged: (value) => setState(() => filter = value.first)),
          const SizedBox(height: 18),
          for (final payment in demoPayments.where((p) => filter == 'All' || p.status == filter))
            Surface(
              onTap: () => openPage(context, PaymentDetailPage(payment: payment)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleAvatar(backgroundColor: mint, foregroundColor: emerald, child: Text(payment.initials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(payment.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Cycle #02 · Due Sep 22', style: TextStyle(color: muted, fontSize: 11))])), Badge('• ${payment.status}', color: statusColor(payment.status))]),
                const Divider(height: 28, color: canvas),
                Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PENDING AMOUNT', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1)), SizedBox(height: 5), Text('Rs. 25,000', style: TextStyle(fontWeight: FontWeight.w800))])), Badge('${payment.days} days overdue', color: statusColor(payment.status)), const Icon(Icons.chevron_right, color: muted)]),
                if (reminders.contains(payment.reference)) const Padding(padding: EdgeInsets.only(top: 12), child: Text('✓ Reminder preview created', style: TextStyle(color: emerald, fontSize: 11))),
              ]),
            ),
          const Text('Sample records · Select a member to inspect their payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted)),
        ],
      );
}

class PaymentDetailPage extends StatelessWidget {
  final MemberPayment payment;
  const PaymentDetailPage({super.key, required this.payment});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Payment Details', subtitle: 'Record & collection ledger', trailing: Badge(payment.reference),
        children: [
          HeroCard(label: 'Total amount due', amount: 'Rs. 25,000.00', caption: 'Monthly installment for Cycle #02 · Past scheduled settlement', tag: '${payment.days} DAYS LATE', children: [const Divider(color: Color(0xFF46A875), height: 28), const DetailRow('Due date', 'Sep 22, 2026', color: Colors.white), DetailRow('Late penalty', 'Rs. ${payment.days * 50}.00 accrued', color: const Color(0xFFFFD982))]),
          Surface(child: Row(children: [CircleAvatar(backgroundColor: mint, foregroundColor: emerald, child: Text(payment.initials)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(payment.name, style: const TextStyle(fontWeight: FontWeight.w700)), const Text('Member · IT-0491-401 · Tier 1 Account', style: TextStyle(color: muted, fontSize: 10))])), IconButton(tooltip: 'Contact member', onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text('Contact ${payment.name}'), content: const Text('Contact details will be available when member accounts are connected.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))])), icon: const Icon(Icons.phone_outlined, color: emerald))])),
          const SectionLabel('Transaction specifications'),
          Surface(child: Column(children: [DetailRow('Record voucher', payment.reference), const DetailRow('Assigned amount', 'Rs. 25,000.00'), const DetailRow('Maturity date', 'Sep 22, 2026'), DetailRow('Payment status', '${payment.status} (${payment.days} days late)', color: statusColor(payment.status))])),
          const SectionLabel('Communication history'),
          const Surface(child: Column(children: [HistoryEntry(icon: Icons.chat_bubble_outline, title: 'Automated SMS & WhatsApp', caption: 'Scheduled reminder preview for the overdue installment.', date: '3 days ago'), Divider(color: canvas), HistoryEntry(icon: Icons.receipt_outlined, title: 'Billing notice issued', caption: 'Original invoice issued to the member’s account.', date: 'Sep 22, 2026')])),
          const Surface(child: Row(children: [Icon(Icons.info_outline, color: emerald, size: 18), SizedBox(width: 10), Expanded(child: Text('Amounts, penalties and communication history are sample data for the UI preview.', style: TextStyle(fontSize: 11, color: muted)))])),
        ],
      );
}

class HistoryEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final String date;
  const HistoryEntry({super.key, required this.icon, required this.title, required this.caption, required this.date});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: emerald, size: 18), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(caption, style: const TextStyle(fontSize: 11, color: muted, height: 1.5)), const SizedBox(height: 5), Text(date, style: const TextStyle(fontSize: 10, color: muted))]))]);
}

class PayoutMember {
  final String name;
  final String status;
  final String date;
  const PayoutMember(this.name, this.status, this.date);
}

const payoutMembers = [
  PayoutMember('Kiara Jaxson', 'Paid', 'Jun 15, 2026'),
  PayoutMember('Kevin Dixon', 'Paid', 'Jul 15, 2026'),
  PayoutMember('Rose Peterkin', 'Paid', 'Aug 15, 2026'),
  PayoutMember('Marcus Vance', 'Current', 'Oct 15, 2026'),
  PayoutMember('Victor Hussain', 'Upcoming', 'Nov 15, 2026'),
  PayoutMember('Alice Cameron', 'Upcoming', 'Dec 15, 2026'),
];

class PayoutPage extends StatelessWidget {
  const PayoutPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Payouts', subtitle: 'Cycle disbursement tracking', trailing: const Badge('Cycle 4 of 12'),
        footer: FilledButton.icon(onPressed: () => openPage(context, const RulesPage()), icon: const Icon(Icons.description_outlined, size: 18), label: const Text('View Rules')),
        children: [
          HeroCard(label: 'Cycle progress', amount: 'Rs. 10,000', caption: 'Current payout cycle: Cycle 4 of 12', tag: 'On schedule', children: [const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('33.3% disbursed'), Text('4 / 12 completed')]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: 4 / 12, minHeight: 6, color: Color(0xFF96E5B8), backgroundColor: Color(0xFF3C9D68))), const Divider(color: Color(0xFF46A875), height: 28), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FULL POT\nRs. 10,000', style: TextStyle(height: 1.6)), Text('CURRENT TURN\nMarcus Vance', textAlign: TextAlign.right, style: TextStyle(height: 1.6))])]),
          const SectionLabel('Distribution schedule · ordered by slot'),
          for (var i = 0; i < payoutMembers.length; i++)
            Surface(
              border: payoutMembers[i].status == 'Current' ? emerald : null,
              onTap: () => openPage(context, PayoutDetailPage(member: payoutMembers[i], position: i + 1)),
              child: Row(children: [CircleAvatar(radius: 17, backgroundColor: payoutMembers[i].status == 'Current' ? emerald : mint, foregroundColor: payoutMembers[i].status == 'Current' ? Colors.white : emerald, child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(payoutMembers[i].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 4), Text(payoutMembers[i].status == 'Current' ? 'Processing payout today' : payoutMembers[i].date, style: const TextStyle(fontSize: 11, color: muted))])), Badge(payoutMembers[i].status == 'Paid' ? '✓ Paid' : payoutMembers[i].status, color: payoutMembers[i].status == 'Upcoming' ? muted : payoutMembers[i].status == 'Current' ? ink : emerald)]),
            ),
          const Text('Showing 6 of 12 sample slots.', style: TextStyle(color: muted, fontSize: 11)),
        ],
      );
}

class PayoutDetailPage extends StatelessWidget {
  final PayoutMember member;
  final int position;
  const PayoutDetailPage({super.key, required this.member, required this.position});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Payout Details', subtitle: 'Account · Chit Fund Pool #26', trailing: Badge('DISB-$position-99201'),
        footer: OutlinedButton.icon(onPressed: () => openPage(context, const RulesPage()), icon: const Icon(Icons.verified_user_outlined, size: 18), label: const Text('View Payout Rules')),
        children: [
          HeroCard(label: member.status == 'Current' ? 'Current payout turn' : '${member.status} payout', amount: 'Rs. 10,000.00', caption: 'Slot #$position of 12 · Cycle 2026', tag: 'Direct transfer'),
          Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('●  SUMMARY BOX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 14), Row(children: [CircleAvatar(radius: 18, backgroundColor: mint, foregroundColor: emerald, child: Text(member.name.split(' ').map((s) => s[0]).join(), style: const TextStyle(fontSize: 12))), const SizedBox(width: 10), Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700))), const Badge('✓ Verified')]), const Divider(color: canvas, height: 28), DetailRow('Position', '#$position / 12'), const DetailRow('Amount', 'Rs. 10,000.00'), const DetailRow('Method', 'Bank transfer'), DetailRow('Payout date', member.date), DetailRow('Status', member.status == 'Current' ? 'Processing release' : member.status, color: member.status == 'Current' ? const Color(0xFFB57A18) : emerald)])),
          const Surface(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.shield_outlined, color: emerald, size: 20), SizedBox(width: 10), Expanded(child: Text('Payouts follow the agreed group order. This preview displays payout information; transfer processing will be connected later.', style: TextStyle(color: muted, fontSize: 12, height: 1.6)))])),
        ],
      );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Marcus Vance';
  String email = 'marcus@example.com';
  bool notifications = true;
  bool sharing = false;
  bool largeText = false;

  Future<void> editAccount() async {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Account details'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name'), validator: (value) => (value ?? '').trim().length < 2 ? 'Enter your full name' : null), TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value ?? '') ? null : 'Enter a valid email')])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save'))],
    ));
    if (saved == true && mounted) {
      setState(() { name = nameController.text.trim(); email = emailController.text.trim(); });
      feedback(context, 'Account updated for this preview session.');
    }
    // Wait for the dialog route to finish its closing animation before disposing.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    emailController.dispose();
  }

  void setting(String title, String description, bool value, ValueChanged<bool> update) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 12), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(description), value: value, onChanged: (next) { refresh(() => value = next); update(next); }), const SizedBox(height: 12), const Text('Preferences apply to this preview session.', style: TextStyle(color: muted, fontSize: 12))])))));
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(largeText ? 1.2 : 1)),
        child: PageFrame(title: 'Profile', subtitle: 'Account & preferences', trailing: IconButton(tooltip: 'Edit account', onPressed: editAccount, icon: const Icon(Icons.edit_outlined, color: emerald, size: 20)), children: [
          Surface(child: SizedBox(width: double.infinity, child: Column(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF67CBA3), width: 2), gradient: const LinearGradient(colors: [mint, Color(0xFFB3EAD7)])), child: const CircleAvatar(radius: 38, backgroundColor: Color(0xFFB3EAD7), child: Icon(Icons.person, size: 55, color: Color(0xFF267B62)))), const SizedBox(height: 14), Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(email, style: const TextStyle(fontSize: 12, color: muted)), const SizedBox(height: 10), const Badge('IT0491-401 · Chit Fund Pool #26'), const SizedBox(height: 12), const Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [Badge('● STATUS: ACTIVE'), Badge('♟ ROLE: PARTICIPANT', color: muted)])]))),
          const SectionLabel('System settings & controls'),
          SettingsTile(number: '01', title: 'ACCOUNT', subtitle: 'Personal details, chit pool status & identity', tag: 'KYC Verified', onTap: editAccount),
          SettingsTile(number: '02', title: 'SECURITY', subtitle: 'Biometric access, login PIN & password', tag: 'PIN ON', onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Security'), content: const Text('Login PIN, biometric access and password controls will be connected during the authentication phase.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))]))),
          SettingsTile(number: '03', title: 'PRIVACY', subtitle: 'Data sharing, ledger anonymization & audit', onTap: () => setting('Privacy', 'Share payout updates with trusted people', sharing, (v) => setState(() => sharing = v))),
          SettingsTile(number: '04', title: 'NOTIFICATION', subtitle: 'Pool alerts, payout notice & payment reminders', tag: notifications ? 'ON' : 'OFF', onTap: () => setting('Notifications', 'Show payment reminder previews', notifications, (v) => setState(() => notifications = v))),
          SettingsTile(number: '05', title: 'ACCESSIBILITY', subtitle: 'Display size, high contrast & haptic feedback', onTap: () => setting('Accessibility', 'Use larger profile text', largeText, (v) => setState(() => largeText = v))),
        ]),
      );
}

class SettingsTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final String? tag;
  final VoidCallback onTap;
  const SettingsTile({super.key, required this.number, required this.title, required this.subtitle, required this.onTap, this.tag});
  @override
  Widget build(BuildContext context) => Surface(onTap: onTap, child: Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(10)), child: Text(number, style: const TextStyle(fontSize: 11, color: emerald, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), if (tag != null) Text(tag!, style: const TextStyle(fontSize: 9, color: emerald))]), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 11, color: muted, height: 1.5))])), const Icon(Icons.chevron_right, size: 18, color: muted)]));
}

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});
  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  String tab = 'General';
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Rules & Guidelines', subtitle: '• Seettū Governance v2.4', trailing: const Icon(Icons.verified_user, color: emerald, size: 20),
        children: [
          const HeroCard(label: 'Chit pool standard agreement', amount: 'Rs. 250,000', caption: 'Pool agreement · 10 months · 10 peers', tag: 'Protected', children: [SizedBox(height: 14), Divider(color: Color(0xFF46A875)), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CYCLE SPAN\n10 months', style: TextStyle(fontSize: 11, height: 1.8)), Text('MAX DISCOUNT\n35% cap', style: TextStyle(fontSize: 11, height: 1.8)), Text('TOTAL SEATS\n10 peers', style: TextStyle(fontSize: 11, height: 1.8))])]),
          SegmentedButton<String>(segments: const [ButtonSegment(value: 'General', label: Text('General')), ButtonSegment(value: 'Rules', label: Text('Rules')), ButtonSegment(value: 'Penalties', label: Text('Penalties'))], selected: {tab}, onSelectionChanged: (value) => setState(() => tab = value.first)),
          const SizedBox(height: 20),
          if (tab == 'General') ...[
            const RuleCard(icon: Icons.calendar_month_outlined, title: '1. Contribution Schedule', badge: 'Monthly', children: [Text('Mandatory recurring cycle maintenance', style: TextStyle(fontSize: 12, color: muted)), DetailRow('Due date window', '1st–10th of every month'), DetailRow('Fixed installment', 'Rs. 25,000.00', color: emerald), DetailRow('Cycle clearance health', '98.4% on time', color: emerald), LinearProgressIndicator(value: 0.984, color: emerald, backgroundColor: mint), SizedBox(height: 12), Text('Contributions are recorded by the organizer. Auto-debit and bank transfers are represented as UI examples.', style: TextStyle(fontSize: 12, color: muted, height: 1.6))]),
            const RuleCard(icon: Icons.gavel_outlined, title: '2. Bidding & Payouts', badge: 'Transparent', children: [Text('The full pot is assigned to one member in the agreed payout order. Members can inspect their slot and payout date in the schedule.', style: TextStyle(color: muted, fontSize: 12, height: 1.6))]),
          ],
          if (tab == 'Rules') ...[
            const RuleCard(icon: Icons.groups_outlined, title: 'Agreed payout order', badge: 'Shared', children: [Text('Every member can view the payout sequence. Changes require agreement from the group and an updated shared record.', style: TextStyle(color: muted, fontSize: 13, height: 1.6))]),
            const RuleCard(icon: Icons.fact_check_outlined, title: 'Payment records', badge: 'Verified', children: [Text('The organizer records contributions. Each record should include the amount, due date, status and reference so members can check it.', style: TextStyle(color: muted, fontSize: 13, height: 1.6))]),
          ],
          if (tab == 'Penalties') ...[
            const RuleCard(icon: Icons.timer_outlined, title: 'Grace period', badge: '7 days', children: [Text('An overdue contribution is marked Late during the seven-day grace period. After that period it is marked Missed.', style: TextStyle(color: muted, fontSize: 13, height: 1.6))]),
            const RuleCard(icon: Icons.error_outline, title: 'Late payment review', badge: 'Sample policy', children: [Text('The payment-detail preview uses Rs. 50 per overdue day to demonstrate a penalty display. The actual penalty must follow the group’s agreed policy.', style: TextStyle(color: muted, fontSize: 13, height: 1.6))]),
          ],
          const Text('Agreement values are prototype examples. Payout and contribution screens demonstrate separate sample pools.', style: TextStyle(color: muted, fontSize: 11, height: 1.6)),
        ],
      );
}

class RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final List<Widget> children;
  const RuleCard({super.key, required this.icon, required this.title, required this.badge, required this.children});
  @override
  Widget build(BuildContext context) => Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: emerald, size: 22), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))), Badge(badge)]), const SizedBox(height: 14), ...children]));
}
