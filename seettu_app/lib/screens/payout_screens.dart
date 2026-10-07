import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../services/current_group.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WithCurrentGroup(
      builder: (context, groups, group, reload) => AppScreen(
        title: 'Payout Schedule',
        onRefresh: reload,
        children: [
          GroupPickerBar(groups: groups, group: group, onSelect: (id) => context.read<AppState>().setGroupId(id)),
          if (group != null)
            FutureBuilder<Map<String, dynamic>>(
              future: api.get('/groups/${group['id']}/payouts'),
              builder: (context, snap) {
                if (!snap.hasData) return const Padding(padding: EdgeInsets.only(top: 24), child: LoadingBox());
                if (snap.hasError) return Padding(padding: const EdgeInsets.only(top: 16), child: ErrorBox(message: errMsg(snap.error!)));
                final data = snap.data!;
                final payouts = (data['payouts'] as List).cast<Map<String, dynamic>>();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle('Payout order · pot ${rs(data['potAmount'] as num?)}'),
                  if (payouts.isEmpty)
                    const EmptyBox(text: 'Add members to see the payout order.')
                  else
                    ...payouts.map((p) {
                      final current = p['status'] == 'Current';
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        borderColor: current ? AppColors.primary : null,
                        borderWidth: current ? 2 : 1,
                        onTap: () => Navigator.of(context).pushNamed('/payout-details', arguments: {'payout': p, 'groupName': group['name']}),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: current ? AppColors.primary : AppColors.grey, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: AppText('${p['position']}', weight: FontWeight.w700, color: current ? Colors.white : AppColors.ink),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              AppText(p['name'] as String, weight: FontWeight.w700),
                              AppText('${fmtDate(p['date'])} · ${rs(p['amount'] as num?)}', size: 13, color: AppColors.mute),
                            ]),
                          ),
                          StatusTag(p['status'] as String),
                        ]),
                      );
                    }),
                  PrimaryButton(
                    title: 'View Rules',
                    icon: Icons.description_outlined,
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pushNamed('/rules'),
                  ),
                ]);
              },
            ),
        ],
      ),
    );
  }
}

class PayoutDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> payout;
  final String groupName;
  const PayoutDetailsScreen({super.key, required this.payout, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Payout Details',
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: AppText(payout['name'] as String, size: 20, weight: FontWeight.w800)),
              StatusTag(payout['status'] as String),
            ]),
            const SizedBox(height: 6),
            KVRow(label: 'Group', value: groupName),
            KVRow(label: 'Payout position', value: '#${payout['position']}'),
            KVRow(label: 'Payout amount', value: rs(payout['amount'] as num?)),
            KVRow(label: 'Payout date', value: fmtDate(payout['date'])),
            KVRow(label: 'Status', value: payout['status'] as String),
          ]),
        ),
      ],
    );
  }
}

const _rules = [
  ['Contribution Schedule', 'Every active member pays the agreed contribution once per cycle. The due day is the day of the month the group started (up to the 28th).'],
  ['Disbursement & Bidding Protocol', 'The full pot is paid to one member per cycle, in the payout order shown in the app. The order changes only if the whole group agrees.'],
  ['Default & Grace Period Policies', 'Payments have a 7-day grace period after the due date and show as Late. After the grace period they show as Missed and the organizer can send a reminder.'],
];

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Rules & Guidelines',
      children: [
        for (var i = 0; i < _rules.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: AppText('${i + 1}', weight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(child: AppText(_rules[i][0], weight: FontWeight.w700, size: 16)),
              ]),
              const SizedBox(height: 6),
              AppText(_rules[i][1], color: AppColors.mute),
            ]),
          ),
        const AppText(
          'This app tracks contributions. It does not move money, give financial or legal advice, or settle disputes.',
          size: 13,
          color: AppColors.mute,
        ),
      ],
    );
  }
}
