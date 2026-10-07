import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/loader.dart';
import '../services/tab_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning,';
  if (h < 18) return 'Good afternoon,';
  return 'Good evening,';
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              AppText(title, weight: FontWeight.w700),
              AppText(sub, size: 13, color: AppColors.mute),
            ]),
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataLoader<Map<String, dynamic>>(
      load: () async => (await api.get('/dashboard')),
      builder: (context, d, reload) {
        final recent = (d['recent'] as List).cast<Map<String, dynamic>>();
        final nextUp = d['nextUp'] as Map<String, dynamic>?;
        final missedCount = (d['missedCount'] as num?)?.toInt() ?? 0;

        return AppScreen(
          onRefresh: reload,
          children: [
            AppText(_greeting(), color: AppColors.mute),
            AppText(d['name']?.toString() ?? '', size: 24, weight: FontWeight.w800),
            const SizedBox(height: 14),
            HeroCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppText('Total Savings (All Groups)', size: 14, color: Color(0xFFD7F0E1)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AppText(rs(d['totalSavings'] as num?), size: 32, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const AppText('Total Groups', size: 13, color: Color(0xFFD7F0E1)),
                    AppText('${d['activeGroups']} Active', weight: FontWeight.w700, color: Colors.white),
                  ]),
                  const SizedBox(width: 32),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const AppText('Total Members', size: 13, color: Color(0xFFD7F0E1)),
                    AppText('${d['totalMembers']} Circles', weight: FontWeight.w700, color: Colors.white),
                  ]),
                ]),
              ]),
            ),
            if (missedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pushNamed('/missed-late'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.error, color: AppColors.red, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AppText('$missedCount Missed Payment${missedCount > 1 ? 's' : ''}', weight: FontWeight.w700, color: AppColors.red),
                          AppText('${d['missedGroupName'] ?? ''} · Tap to resolve', size: 13, color: AppColors.mute),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.red),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(children: [
                _Tile(icon: Icons.payments_outlined, title: 'Payment', sub: 'Dashboard view', onTap: () => context.read<TabState>().go(2)),
                const SizedBox(width: 12),
                _Tile(icon: Icons.calendar_month_outlined, title: 'Payout List', sub: 'Rotation queues', onTap: () => Navigator.of(context).pushNamed('/payouts')),
              ]),
            ),
            if (nextUp != null)
              AppCard(
                margin: const EdgeInsets.only(top: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppText('NEXT UP', size: 12, weight: FontWeight.w700, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AppText('Contribution: ${rs(nextUp['amount'] as num?)}', weight: FontWeight.w700, size: 17),
                        AppText('Due ${fmtDate(nextUp['dueDate'])} · ${nextUp['groupName']}', size: 13, color: AppColors.mute),
                      ]),
                    ),
                    SizedBox(
                      width: 120,
                      child: PrimaryButton(
                        title: 'Pay Now',
                        onPressed: () => Navigator.of(context).pushNamed('/record-payment', arguments: {
                          'groupId': nextUp['groupId'],
                          'memberId': nextUp['memberId'],
                          'month': nextUp['month'],
                        }),
                      ),
                    ),
                  ]),
                ]),
              ),
            const SectionTitle('Recent Activity'),
            if (recent.isEmpty)
              const EmptyBox(text: 'No payments recorded yet.')
            else
              ...recent.map((p) => AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_upward, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AppText('Payment from ${p['memberName']}', weight: FontWeight.w600),
                          AppText('${fmtDate(p['date'])} · ${p['groupName']}', size: 13, color: AppColors.mute),
                        ]),
                      ),
                      AppText(rs(p['amount'] as num?), weight: FontWeight.w700),
                    ]),
                  )),
          ],
        );
      },
    );
  }
}
