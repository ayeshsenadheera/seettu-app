import 'package:flutter/material.dart';

class SharedPaymentRecordsScreen extends StatelessWidget {
  const SharedPaymentRecordsScreen({super.key});

  static const Color green = Color(0xFF078653);
  static const Color dark = Color(0xFF172238);
  static const Color muted = Color(0xFF8EA1BE);
  static const Color border = Color(0xFFE3EAF2);

  static const List<Map<String, String>> members = [
    {'name': 'Arron Finch', 'date': '22 Sep 2026'},
    {'name': 'Alen Makrem', 'date': '21 Sep 2026'},
    {'name': 'Glenn Philips', 'date': '25 Sep 2026'},
    {'name': 'Jos Butler', 'date': '23 Sep 2026'},
    {'name': 'Thilak Varma', 'date': '20 Sep 2026'},
    {'name': 'Kusal Mendis', 'date': '25 Sep 2026'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  children: [
                    _groupCard(),
                    const SizedBox(height: 18),
                    _monthCard(),
                    const SizedBox(height: 18),
                    _summaryCard(),
                    const SizedBox(height: 24),
                    _contributionHeader(),
                    const SizedBox(height: 12),
                    ...members.map(_memberCard),
                  ],
                ),
              ),
              _cancelButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: dark),
          ),
          const Expanded(
            child: Text(
              'Shared Payment Records',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _groupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF078653), Color(0xFF008263)],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22007850),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: green,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    const Text(
                      'Friend Seettu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x337FFFFF),
                        border: Border.all(color: Colors.white38),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Monthly Contribution',
                  style: TextStyle(
                    color: Color(0xFFC2E8D9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Rs. 10,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _monthCard() {
    return Container(
      width: double.infinity,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: const Text(
        'September 2026',
        style: TextStyle(
          color: dark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _summaryItem('Total\nMembers', '8', dark),
          _verticalDivider(),
          _summaryItem('Paid', '6', green),
          _verticalDivider(),
          _summaryItem('Pending', '1', const Color(0xFFE37C00)),
          _verticalDivider(),
          _summaryItem('Late', '1', const Color(0xFFF04460)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667B99),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 53,
      width: 1,
      color: border,
    );
  }

  Widget _contributionHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'MEMBER CONTRIBUTIONS',
            style: TextStyle(
              color: Color(0xFF667B99),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '6 of 8 Completed',
          style: TextStyle(
            color: green,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _memberCard(Map<String, String> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF70829E),
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name']!,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rs. 10,000',
                  style: TextStyle(
                    color: Color(0xFF384860),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid on ${member['date']}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFF3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFADF0CF)),
            ),
            child: const Text(
              'Paid',
              style: TextStyle(
                color: green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFE5EAF2),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
