import 'package:flutter/material.dart';
import 'record_payment.dart';
import 'payment_history.dart';

class PaymentDashboard extends StatelessWidget {
  const PaymentDashboard({super.key});

  static const Color green = Color(0xFF087747);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF19263B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Group card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friend Seettu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Monthly Contribution',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Rs. 10,000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Payment Summary'),
          const SizedBox(height: 12),

          // Summary card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: _cardDecoration(),
            child: const Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Monthly\nAmount',
                    value: 'Rs.10,000',
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Next Due\nDate',
                    value: '25 Sep 2026',
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'My\nStatus',
                    value: 'PENDING',
                    isStatus: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),
          const _SectionTitle('Current Payment'),
          const SizedBox(height: 12),

          // Current payment card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'September 2026',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 18),
                const _DetailRow('Amount', 'Rs.10,000'),
                const _DetailRow('Due Date', '25 Sep 2026'),
                const _DetailRow('Status', 'Pending'),
                const Divider(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecordPaymentScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD5DEE8),
                      foregroundColor: textColor,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Record Payment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),
          const _SectionTitle('Quick Action'),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.access_time,
            title: 'My Payment History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentHistoryScreen(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.people_outline,
            title: 'Shared Payment Records',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.notifications_none,
            title: 'Payment Reminder',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.event_note,
            title: 'Missed/ Late payments',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          OutlinedButton(
            onPressed: () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: background,
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: PaymentDashboard.textColor,
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            : Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: PaymentDashboard.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: PaymentDashboard.background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: PaymentDashboard.textColor,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: PaymentDashboard.textColor,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
