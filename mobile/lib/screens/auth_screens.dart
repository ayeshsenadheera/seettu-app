import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 96});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size / 3)),
          alignment: Alignment.center,
          child: Icon(Icons.groups, size: size * 0.5, color: Colors.white),
        ),
        const SizedBox(height: 10),
        AppText('seettū', size: 28, weight: FontWeight.w800, color: AppColors.primaryDark),
      ]);
}

// Turns a raw FirebaseAuthException into the kind of plain-language message the rest of the app uses.
String firebaseErr(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Cannot reach the network. Check your connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
  return errMsg(e);
}

const _slides = [
  ['Welcome to seettū', 'Run your savings circle in one place, with no notebook and no confusion.'],
  ['Empower your savings with people you trust', 'Create groups, add members, and see who has paid and whose turn is next.'],
  ['Never miss a payment', 'Clear status, reminders and a shared record that everyone can trust.'],
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final last = i == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Logo(),
                  const SizedBox(height: 36),
                  AppText(_slides[i][0], size: 24, weight: FontWeight.w800, align: TextAlign.center),
                  const SizedBox(height: 10),
                  AppText(_slides[i][1], color: AppColors.mute, align: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (k) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: k == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: k == i ? AppColors.primary : AppColors.line, borderRadius: BorderRadius.circular(4)),
                        )),
                  ),
                ]),
              ),
            ),
            PrimaryButton(
              title: last ? 'Get Started' : 'Continue',
              onPressed: () {
                if (last) {
                  Navigator.of(context).pushReplacementNamed('/login');
                } else {
                  setState(() => i++);
                }
              },
            ),
            if (!last)
              PrimaryButton(title: 'Skip', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pushReplacementNamed('/login')),
          ]),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;

  Future<void> submit() async {
    if (!validEmail(email.text) || password.text.isEmpty) {
      setState(() => error = 'Enter your email and password.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      // AppState listens for the auth change and loads the profile; nothing else to do here.
    } catch (e) {
      setState(() => error = firebaseErr(e));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            const Center(child: Logo(size: 80)),
            const SizedBox(height: 24),
            const AppText('Welcome Back!', size: 26, weight: FontWeight.w800, align: TextAlign.center),
            const SizedBox(height: 4),
            const AppText('Login to continue to your account', color: AppColors.mute, align: TextAlign.center),
            AppField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress, placeholder: 'you@example.com'),
            AppField(label: 'Password', controller: password, obscure: true, placeholder: 'Your password'),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(error!, color: AppColors.red)),
            PrimaryButton(title: 'Log In', onPressed: submit, loading: busy),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const AppText("Don't have an account?", color: AppColors.mute),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/signup'),
                child: const AppText('Create account', weight: FontWeight.w700, color: AppColors.primary),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  Map<String, String> errors = {};
  bool busy = false;

  Future<void> submit() async {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'Enter your full name.';
    if (!validPhone(phone.text)) e['phone'] = 'Enter a valid number, like 0771234567.';
    if (!validEmail(email.text)) e['email'] = 'Enter a valid email address.';
    if (password.text.length < 6) e['password'] = 'Use at least 6 characters.';
    if (confirm.text != password.text) e['confirm'] = 'Passwords do not match.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } catch (err) {
      setState(() { errors = {'form': firebaseErr(err)}; busy = false; });
      return;
    }
    if (!mounted) return;
    try {
      // Fill in the details Firebase doesn't collect (name, phone) on our own backend.
      await context.read<AppState>().completeSignUp(name: name.text, phone: phone.text);
    } catch (err) {
      // The Firebase account was created but saving the profile failed (e.g. server not
      // running). Sign back out so the person can try again cleanly from this form.
      await FirebaseAuth.instance.signOut();
      setState(() => errors = {'form': errMsg(err)});
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Create account',
      children: [
        AppField(label: 'Full name', controller: name, error: errors['name']),
        AppField(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone, placeholder: '07X XXX XXXX', error: errors['phone']),
        AppField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress, error: errors['email']),
        AppField(label: 'Password', controller: password, obscure: true, error: errors['password']),
        AppField(label: 'Confirm password', controller: confirm, obscure: true, error: errors['confirm']),
        if (errors['form'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: AppText(errors['form']!, color: AppColors.red)),
        PrimaryButton(title: 'Sign Up', onPressed: submit, loading: busy),
        PrimaryButton(title: 'I already have an account', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
