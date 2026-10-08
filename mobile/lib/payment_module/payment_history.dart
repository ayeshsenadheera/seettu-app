import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  static const Color green = Color(0xFF07864E);
  static const Color dark = Color(0xFF172238);
  static const Color muted = Color(0xFF8FA2BF);

  static const List<Map<String, String>> payments = [
    {'month': 'September 2026', 'date': '22 September 2026'},
    {'month': 'August 2026', 'date': '24 August 2026'},
    {'month': 'July 2026', 'date': '20 July 2026'},
    {'month': 'June 2026', 'date': '21 June 2026'},
    {'month': 'May 2026', 'date': '23 May 2026'},
  ];

  void showDownloadMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt download will be available soon'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Payment History',
          style: TextStyle(
            color: dark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: dark),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    groupCard(),
                    const SizedBox(height: 18),
                    summaryCard(),
                    const SizedBox(height: 25),
                    historyHeader(context),
                    const SizedBox(height: 14),
                    ...payments.map(
                      (payment) => paymentCard(context, payment),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFE0E7EF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Color(0xFF34445C),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget groupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FFF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: green,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Friend Seettu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFF2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monthly Contribution',
                  style: TextStyle(
                    color: Color(0xFFB7E6D1),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rs. 10,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }

  Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 19,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF0FFF8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: green, size: 16),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'TOTAL PAID',
                        style: TextStyle(
                          color: Color(0xFF687F9D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Text(
                  'Rs. 80,000',
                  style: TextStyle(
                    color: dark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 52,
            width: 1,
            color: const Color(0xFFE0E7EF),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: green, size: 16),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'TOTAL PAYMENTS',
                        style: TextStyle(
                          color: Color(0xFF687F9D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      '8',
                      style: TextStyle(
                        color: dark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'installments',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget historyHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'PAYMENT HISTORY',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '5 recent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF40536D),
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => showDownloadMessage(context),
          child: const Row(
            children: [
              Text(
                'Download All',
                style: TextStyle(
                  color: Color(0xFF00A56A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.download,
                color: Color(0xFF00A56A),
                size: 17,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget paymentCard(
    BuildContext context,
    Map<String, String> payment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE4EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFF3),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC4F5DC)),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF00A56A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['month']!,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rs. 10,000',
                  style: TextStyle(
                    color: dark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Paid on ${payment['date']}',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.file_upload_outlined,
              color: muted,
              size: 21,
            ),
            onPressed: () => showDownloadMessage(context),
          ),
        ],
      ),
    );
  }
}
