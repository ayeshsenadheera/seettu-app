import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  static const green = Color(0xFF07864E);
  static const dark = Color(0xFF172238);
  static const muted = Color(0xFF8FA2BF);

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> payments = [];

  String? selectedGroupId;
  String? error;

  double totalPaid = 0;
  int paymentCount = 0;
  bool loading = true;
  bool loadingHistory = false;
  bool canManage = false;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await api.get('/groups');
      final loaded = (result['groups'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        groups = loaded;
        selectedGroupId =
            loaded.isNotEmpty ? loaded.first['id'].toString() : null;
        loading = false;
      });

      if (selectedGroupId != null) {
        await loadHistory();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = errMsg(e);
        loading = false;
      });
    }
  }

  Future<void> loadHistory() async {
    final groupId = selectedGroupId;
    if (groupId == null) return;

    setState(() {
      loadingHistory = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        paymentService.getHistory(groupId),
        paymentService.getSummary(groupId),
      ]);

      final history = results[0];
      final summary = results[1];

      if (!mounted || selectedGroupId != groupId) return;

      setState(() {
        payments = (history['payments'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        totalPaid = (history['totalPaid'] as num?)?.toDouble() ?? 0;
        paymentCount = (history['count'] as num?)?.toInt() ?? 0;
        canManage = summary['canManage'] == true;
        loadingHistory = false;
      });
    } catch (e) {
      if (!mounted || selectedGroupId != groupId) return;
      setState(() {
        error = errMsg(e);
        loadingHistory = false;
      });
    }
  }

  Map<String, dynamic>? get selectedGroup {
    for (final group in groups) {
      if (group['id'].toString() == selectedGroupId) {
        return group;
      }
    }
    return null;
  }

  String money(dynamic amount) {
    final value = (amount is num)
        ? amount.toDouble()
        : double.tryParse(amount?.toString() ?? '') ?? 0;

    final whole = value.toStringAsFixed(0);
    final formatted = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'Rs. $formatted';
  }

  String monthLabel(dynamic value) {
    final text = value?.toString() ?? '';
    final parts = text.split('-');

    if (parts.length != 2) return text;

    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) {
      return text;
    }

    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${names[month - 1]} ${parts[0]}';
  }

  String dateLabel(dynamic value) {
    if (value == null) return 'Unknown date';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day} ${monthLabel('${date.year}-${date.month.toString().padLeft(2, '0')}')}';
  }

  void showDownloadMessage() {
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
        title: Text(
          canManage ? 'Group Payment History' : 'My Payment History',
          style: const TextStyle(
            color: dark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: dark),
            onPressed: loadingHistory ? null : loadHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null && groups.isEmpty
                      ? errorView(loadGroups)
                      : groups.isEmpty
                          ? const Center(
                              child: Text(
                                'No Seettu groups found.',
                                style: TextStyle(color: muted),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: loadHistory,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  groupCard(),
                                  const SizedBox(height: 18),
                                  summaryCard(),
                                  const SizedBox(height: 25),
                                  historyHeader(),
                                  const SizedBox(height: 14),
                                  if (loadingHistory)
                                    const Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (error != null)
                                    errorView(loadHistory)
                                  else if (payments.isEmpty)
                                    emptyHistory()
                                  else
                                    ...payments.map(paymentCard),
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
                    side: const BorderSide(
                      color: Color(0xFFE0E7EF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Color(0xFF34445C),
                      fontWeight: FontWeight.bold,
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

  Widget errorView(Future<void> Function() retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: retry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget groupCard() {
    final group = selectedGroup;

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
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGroupId,
                    isExpanded: true,
                    dropdownColor: green,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    items: groups.map((g) {
                      return DropdownMenuItem<String>(
                        value: g['id'].toString(),
                        child: Text(
                          g['name']?.toString() ?? 'Unnamed Group',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null || value == selectedGroupId) {
                        return;
                      }

                      setState(() {
                        selectedGroupId = value;
                        payments = [];
                        totalPaid = 0;
                        paymentCount = 0;
                        canManage = false;
                      });

                      loadHistory();
                    },
                  ),
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
                Text(
                  money(group?['contribution']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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
        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: summaryItem(
              Icons.attach_money,
              'TOTAL PAID',
              money(totalPaid),
            ),
          ),
          Container(
            height: 52,
            width: 1,
            color: const Color(0xFFE0E7EF),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: summaryItem(
              Icons.pie_chart_outline,
              'TOTAL PAYMENTS',
              '$paymentCount',
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: green, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF687F9D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            color: dark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget historyHeader() {
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
          child: Text(
            '$paymentCount records',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF40536D),
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: showDownloadMessage,
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

  Widget emptyHistory() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: muted,
              size: 45,
            ),
            SizedBox(height: 12),
            Text(
              'No payment records found',
              style: TextStyle(
                color: dark,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Recorded payments will appear here.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentCard(Map<String, dynamic> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE4EAF1),
        ),
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
              border: Border.all(
                color: const Color(0xFFC4F5DC),
              ),
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
                  monthLabel(payment['month']),
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 3),
                  Text(
                    payment['memberName']?.toString() ?? 'Unknown Member',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  money(payment['amount']),
                  style: const TextStyle(
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
                        'Paid on ${dateLabel(payment['date'])}',
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
          const Icon(
            Icons.check_circle,
            color: green,
            size: 21,
          ),
        ],
      ),
    );
  }
}
