import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(title, weight: FontWeight.w700),
                AppText(sub, size: 13, color: AppColors.mute),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.mute),
          ]),
        ),
      );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay logged in')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<AppState>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    return AppScreen(
      title: 'Profile',
      back: false,
      children: [
        AppCard(
          child: Column(children: [
            AvatarCircle(name: user['name'] as String, size: 84),
            const SizedBox(height: 10),
            AppText(user['name'] as String, size: 22, weight: FontWeight.w800),
            AppText(user['email'] as String, color: AppColors.mute),
            const SizedBox(height: 8),
            const StatusTag('Active'),
            const SizedBox(height: 6),
            AppText('Role: ${user['role']}', size: 13, color: AppColors.mute),
          ]),
        ),
        const SectionTitle('System Settings & Controls'),
        _Item(icon: Icons.person_outline, title: 'Account', sub: 'Personal details and password', onTap: () => Navigator.of(context).pushNamed('/account')),
        _Item(icon: Icons.lock_outline, title: 'Privacy', sub: 'Trusted people and data sharing', onTap: () => Navigator.of(context).pushNamed('/trusted-people')),
        _Item(icon: Icons.notifications_outlined, title: 'Notification', sub: 'Payment reminders', onTap: () => Navigator.of(context).pushNamed('/payment-reminder')),
        _Item(icon: Icons.accessibility_new_outlined, title: 'Accessibility', sub: 'Text size and language', onTap: () => Navigator.of(context).pushNamed('/accessibility')),
        PrimaryButton(title: 'Log out', icon: Icons.logout, variant: ButtonVariant.dangerSolid, onPressed: () => _logout(context)),
      ],
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController emailCtrl;
  Map<String, String> errors = {};
  bool busyProfile = false;
  bool busyReset = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user!;
    name = TextEditingController(text: user['name'] as String);
    phone = TextEditingController(text: user['phone'] as String);
    emailCtrl = TextEditingController(text: user['email'] as String);
  }

  Future<void> saveProfile() async {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'Enter your full name.';
    if (!validPhone(phone.text)) e['phone'] = 'Enter a valid number, like 0771234567.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;
    setState(() => busyProfile = true);
    try {
      final r = await api.put('/auth/me', {'name': name.text, 'phone': phone.text});
      if (mounted) {
        context.read<AppState>().setUser(r['user'] as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your details were updated.')));
      }
    } catch (err) {
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busyProfile = false);
  }

  Future<void> sendReset() async {
    setState(() => busyReset = true);
    try {
      final email = context.read<AppState>().user!['email'] as String;
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send reset email: ${e.toString()}')));
    }
    if (mounted) setState(() => busyReset = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppState>().user!['email'] as String;
    return AppScreen(
      title: 'Account',
      children: [
        const SectionTitle('Personal details'),
        AppField(label: 'Full name', controller: name, error: errors['name']),
        AppField(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone, error: errors['phone']),
        AppField(label: 'Email', controller: emailCtrl, enabled: false),
        if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
        PrimaryButton(title: 'Save Changes', onPressed: saveProfile, loading: busyProfile),
        const SectionTitle('Security'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppText('Your password is managed by Firebase Authentication.', color: AppColors.mute),
            const SizedBox(height: 4),
            AppText("We'll email a reset link to $email.", size: 13, color: AppColors.mute),
            PrimaryButton(title: 'Send Password Reset Email', variant: ButtonVariant.outline, onPressed: sendReset, loading: busyReset),
          ]),
        ),
      ],
    );
  }
}

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  Future<void> _pick(BuildContext context, Map<String, dynamic> patch) async {
    try {
      await context.read<AppState>().saveSettings(patch);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: ${errMsg(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppScreen(
      title: 'Accessibility',
      children: [
        const SectionTitle('Text size'),
        ChipGroup<String>(
          options: const [
            ChipOption('Small', 'Small'),
            ChipOption('Medium', 'Medium'),
            ChipOption('Large', 'Large'),
            ChipOption('Extra Large', 'Extra Large'),
          ],
          value: s.textSize,
          onChanged: (v) => _pick(context, {'textSize': v}),
        ),
        AppCard(
          margin: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            AppText('Preview', weight: FontWeight.w700),
            AppText('Your next payment is due in 3 days. Tap Pay Now to record it.', color: AppColors.mute),
          ]),
        ),
        const SectionTitle('Language'),
        ChipGroup<String>(
          options: const [ChipOption('English', 'English'), ChipOption('සිංහල', 'Sinhala'), ChipOption('தமிழ்', 'Tamil')],
          value: s.language,
          onChanged: (v) => _pick(context, {'language': v}),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: AppText('Your language choice is saved to your account. Sinhala and Tamil screen text is not translated yet.', size: 13, color: AppColors.mute),
        ),
      ],
    );
  }
}
