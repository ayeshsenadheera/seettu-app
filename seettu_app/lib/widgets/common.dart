import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';

/* ---------------------------- formatting helpers ---------------------------- */

String rs(num? n) => 'Rs. ${NumberFormat('#,##0').format(n ?? 0)}';

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

String fmtDate(dynamic v) {
  final d = _asDate(v);
  if (d == null) return '-';
  return DateFormat('dd MMM yyyy').format(d);
}

String monthLabel(String key) {
  final parts = key.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return DateFormat('MMMM yyyy').format(DateTime(y, m, 1));
}

String shiftMonth(String key, int n) {
  final parts = key.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = DateTime(y, m - 1 + n, 1);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

String thisMonthKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

String todayStr() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final letters = parts.take(2).map((w) => w[0]).join();
  return letters.toUpperCase();
}

String? normalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[\s-]'), '');
  if (RegExp(r'^\+94\d{9}$').hasMatch(digits)) digits = '0${digits.substring(3)}';
  return RegExp(r'^0\d{9}$').hasMatch(digits) ? digits : null;
}

bool validPhone(String v) => normalizePhone(v) != null;
bool validEmail(String v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch(v);

/* ---------------------------------- text ------------------------------------ */

/// Text that scales with the Accessibility > Text size setting.
class AppText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final TextAlign? align;
  final int? maxLines;
  const AppText(this.text, {super.key, this.size = 15, this.weight = FontWeight.w400, this.color = AppColors.ink, this.align, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final scale = textScales[context.watch<AppState>().textSize] ?? 1.0;
    return Text(text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(fontSize: size * scale, fontWeight: weight, color: color, height: 1.3));
  }
}

/* --------------------------------- layout ------------------------------------ */

class AppScreen extends StatelessWidget {
  final String? title;
  final bool back;
  final Widget? trailing;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? footer;
  final bool scroll;

  const AppScreen({
    super.key,
    this.title,
    this.back = true,
    this.trailing,
    required this.children,
    this.onRefresh,
    this.footer,
    this.scroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    Widget body = scroll
        ? ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: children)
        : Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(children: children));
    if (onRefresh != null) {
      body = RefreshIndicator(onRefresh: onRefresh!, color: AppColors.primary, child: body);
    }
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: back && canPop
                  ? IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.of(context).pop())
                  : null,
              title: AppText(title!, size: 19, weight: FontWeight.w700),
              actions: trailing == null ? null : [trailing!],
            ),
      body: SafeArea(child: body),
      bottomNavigationBar: footer == null ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: footer)),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final Color? background;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AppColors.line, width: borderWidth),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: card);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: AppText(text, size: 17, weight: FontWeight.w700),
      );
}

class KVRow extends StatelessWidget {
  final String label;
  final String value;
  const KVRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(children: [
          Expanded(child: AppText(label, color: AppColors.mute)),
          Expanded(flex: 1, child: AppText(value, weight: FontWeight.w600, align: TextAlign.right)),
        ]),
      );
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBox({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          AppText(message, color: AppColors.red, align: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            PrimaryButton(title: 'Try again', variant: ButtonVariant.outline, onPressed: onRetry),
          ],
        ]),
      );
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox({super.key, required this.text});
  @override
  Widget build(BuildContext context) => AppCard(child: AppText(text, color: AppColors.mute, align: TextAlign.center));
}

/* --------------------------------- controls ------------------------------------ */

enum ButtonVariant { primary, outline, danger, dangerSolid, ghost }

class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool loading;
  final IconData? icon;
  const PrimaryButton({super.key, required this.title, this.onPressed, this.variant = ButtonVariant.primary, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg, border;
    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary; fg = Colors.white; border = AppColors.primary; break;
      case ButtonVariant.outline:
        bg = Colors.transparent; fg = AppColors.primary; border = AppColors.primary; break;
      case ButtonVariant.danger:
        bg = Colors.transparent; fg = AppColors.red; border = AppColors.red; break;
      case ButtonVariant.dangerSolid:
        bg = AppColors.red; fg = Colors.white; border = AppColors.red; break;
      case ButtonVariant.ghost:
        bg = AppColors.grey; fg = AppColors.ink; border = AppColors.grey; break;
    }
    final disabled = onPressed == null || loading;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            side: BorderSide(color: border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: bg.withOpacity(0.6),
          ),
          child: loading
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
              : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                  AppText(title, weight: FontWeight.w700, size: 16, color: fg),
                ]),
        ),
      ),
    );
  }
}

class AppField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final String? placeholder;

  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppText(label, size: 14, weight: FontWeight.w600),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          enabled: enabled,
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: enabled ? AppColors.card : AppColors.grey,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? AppColors.red : AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: AppText(error!, size: 13, color: AppColors.red)),
      ]),
    );
  }
}

class ChipOption<T> {
  final String label;
  final T value;
  const ChipOption(this.label, this.value);
}

class ChipGroup<T> extends StatelessWidget {
  final List<ChipOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  const ChipGroup({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = o.value == value;
        return GestureDetector(
          onTap: () => onChanged(o.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: on ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: on ? AppColors.primary : AppColors.line),
            ),
            child: AppText(o.label, weight: FontWeight.w600, color: on ? Colors.white : AppColors.ink),
          ),
        );
      }).toList(),
    );
  }
}

const Map<String, List<Color>> _tagColors = {
  'Paid': [AppColors.primaryLight, AppColors.primary],
  'Active': [AppColors.primaryLight, AppColors.primary],
  'Current': [AppColors.primary, Colors.white],
  'Pending': [AppColors.amberLight, AppColors.amber],
  'Upcoming': [AppColors.amberLight, AppColors.amber],
  'Late': [AppColors.orangeLight, AppColors.orange],
  'Missed': [AppColors.redLight, AppColors.red],
  'Inactive': [AppColors.grey, AppColors.mute],
  'N/A': [AppColors.grey, AppColors.mute],
};

class StatusTag extends StatelessWidget {
  final String text;
  const StatusTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = _tagColors[text] ?? [AppColors.grey, AppColors.mute];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(20)),
      child: AppText(text, size: 13, weight: FontWeight.w700, color: c[1]),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  const AvatarCircle({super.key, required this.name, this.size = 42});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: AppText(initials(name), size: size * 0.36, weight: FontWeight.w800, color: AppColors.primary),
      );
}

/// Green "current group" bar used on Payment / Members / Payouts, with a bottom-sheet picker.
class GroupPickerBar extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Map<String, dynamic>? group;
  final ValueChanged<String> onSelect;
  const GroupPickerBar({super.key, required this.groups, required this.group, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (group == null) return const EmptyBox(text: 'Create a group first, then come back here.');
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AppText('Choose a group', size: 18, weight: FontWeight.w700),
              const SizedBox(height: 8),
              ...groups.map((g) => InkWell(
                    onTap: () { onSelect(g['id'] as String); Navigator.pop(ctx); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                      child: Row(children: [
                        Expanded(child: AppText(g['name'] as String, weight: g['id'] == group!['id'] ? FontWeight.w700 : FontWeight.w400)),
                        if (g['id'] == group!['id']) const Icon(Icons.check, size: 20, color: AppColors.primary),
                      ]),
                    ),
                  )),
            ]),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Icon(Icons.groups, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppText(group!['name'] as String, size: 17, weight: FontWeight.w700, color: Colors.white),
              AppText('${group!['frequency']} contribution · ${rs(group!['contribution'] as num?)}', size: 13, color: const Color(0xFFD7F0E1)),
            ]),
          ),
          const Icon(Icons.expand_more, color: Colors.white),
        ]),
      ),
    );
  }
}

/// Green hero card used on Home.
class HeroCard extends StatelessWidget {
  final Widget child;
  const HeroCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}
