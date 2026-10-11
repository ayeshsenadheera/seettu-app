import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import 'payment_service.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});
  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  static const green = Color(0xFF087747);
  static const ink = Color(0xFF19263B);
  static const fieldColor = Color(0xFFE6EBF2);
  final formKey = GlobalKey<FormState>();
  final noteController = TextEditingController();
  final amountController = TextEditingController();
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> members = [];
  String? selectedGroupId;
  String? selectedMemberId;
  late String selectedMonth;
  late DateTime paymentDate;
  bool isLoading = true;
  bool isSaving = false;
  bool isBalanceLoading = false;
  String? balanceError;
  double? contribution;
  double? alreadyPaid;
  double? remainingBalance;
  String? paymentStatus;
  int balanceRequestId = 0;
  String? loadError;
  @override
  void initState() {
    super.initState();
    paymentDate = DateTime.now();
    selectedMonth = DateFormat('yyyy-MM').format(paymentDate);
    loadGroups();
  }

  @override
  void dispose() {
    noteController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(paymentDate);
  String formatMonth(String month) =>
      DateFormat('MMMM yyyy').format(DateTime.parse('$month-01'));
  Map<String, dynamic>? get selectedGroup {
    for (final group in groups) {
      if (group['id'] == selectedGroupId) return group;
    }
    return null;
  }

  Future<void> loadGroups() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final response = await api.get('/groups');
      final loadedGroups = (response['groups'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (loadedGroups.isEmpty) {
        throw ApiException(
          'No Seettu groups found. Please create a group first.',
        );
      }
      if (!mounted) {
  return;
}
      setState(() {
        groups = loadedGroups;
        selectedGroupId = loadedGroups.first['id'].toString();
      });
      await loadMembers(selectedGroupId!);
    } catch (e) {
      if (!mounted) {
  return;
}
      setState(() {
        isLoading = false;
        loadError = errMsg(e);
      });
    }
  }

  Future<void> loadMembers(String groupId) async {
    setState(() {
      isLoading = true;
      selectedMemberId = null;
      members = [];
      balanceRequestId++;
      isBalanceLoading = false;
      balanceError = null;
      contribution = null;
      alreadyPaid = null;
      remainingBalance = null;
      paymentStatus = null;
      loadError = null;
    });
    try {
      final response = await api.get('/groups/$groupId/members');
      final loadedMembers = (response['members'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted || selectedGroupId != groupId) return;
      setState(() {
        members = loadedMembers;
        amountController.clear();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || selectedGroupId != groupId) return;
      setState(() {
        isLoading = false;
        loadError = errMsg(e);
      });
    }
  }

  Future<void> loadBalance() async {
    final groupId = selectedGroupId;
    final memberId = selectedMemberId;
    final month = selectedMonth;
    final requestId = ++balanceRequestId;
    if (groupId == null || memberId == null) {
      setState(() {
        isBalanceLoading = false;
        balanceError = null;
        contribution = null;
        alreadyPaid = null;
        remainingBalance = null;
        paymentStatus = null;
        amountController.clear();
      });
      return;
    }
    setState(() {
      isBalanceLoading = true;
      balanceError = null;
      contribution = null;
      alreadyPaid = null;
      remainingBalance = null;
      paymentStatus = null;
      amountController.clear();
    });
    try {
      final result = await paymentService.getBalance(
        groupId: groupId,
        memberId: memberId,
        month: month,
      );
      if (!mounted ||
          requestId != balanceRequestId ||
          groupId != selectedGroupId ||
          memberId != selectedMemberId ||
          month != selectedMonth) return;
      final remaining = (result['remaining'] as num).toDouble();
      setState(() {
        contribution = (result['contribution'] as num).toDouble();
        alreadyPaid = (result['totalPaid'] as num).toDouble();
        remainingBalance = remaining;
        paymentStatus = result['paymentStatus']?.toString();
        isBalanceLoading = false;
        if (remaining > 0) amountController.text = remaining.toStringAsFixed(2);
      });
    } catch (e) {
      if (!mounted || requestId != balanceRequestId) return;
      setState(() {
        isBalanceLoading = false;
        balanceError = errMsg(e);
      });
    }
  }

  Widget paymentProgressCard() {
    if (selectedMemberId == null) return const SizedBox.shrink();
    if (isBalanceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: green)),
      );
    }
    if (balanceError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(balanceError!, style: const TextStyle(color: Colors.red)),
            TextButton(
                onPressed: loadBalance, child: const Text('Retry balance')),
          ],
        ),
      );
    }
    if (remainingBalance == null) return const SizedBox.shrink();
    final total = contribution ?? 0;
    final paid = alreadyPaid ?? 0;
    final remaining = remainingBalance!;
    final fraction = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    Widget metric(String title, double value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 5),
              Text('Rs. ${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: ink)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD5E9DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Payment Progress',
                style: TextStyle(fontWeight: FontWeight.bold, color: ink)),
            Text(paymentStatus ?? '',
                style:
                    const TextStyle(color: green, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            metric('Contribution', total),
            metric('Already Paid', paid),
            metric('Remaining', remaining),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
              value: fraction,
              color: green,
              backgroundColor: const Color(0xFFDCE6E0),
              minHeight: 7),
          if (remaining <= 0) ...[
            const SizedBox(height: 9),
            const Text('This month is fully paid.',
                style: TextStyle(color: green)),
          ],
        ],
      ),
    );
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected != null && mounted) {
      setState(() => paymentDate = selected);
    }
  }

  Future<void> recordPayment() async {
    if (isSaving ||
        isLoading ||
        isBalanceLoading ||
        loadError != null ||
        balanceError != null ||
        remainingBalance == null) return;
    if (!formKey.currentState!.validate()) return;
    if (selectedGroupId == null || selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group and member.'),
        ),
      );
      return;
    }
    final amount = double.parse(amountController.text.trim());
    if (amount > remainingBalance! + 0.000001) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Amount exceeds the remaining balance.'),
      ));
      return;
    }
    setState(() => isSaving = true);
    try {
      final result = await paymentService.recordPayment(
        groupId: selectedGroupId!,
        memberId: selectedMemberId!,
        amount: amount,
        month: selectedMonth,
        date: paymentDate,
        method: 'Cash',
        reference: noteController.text.trim(),
      );
      if (!mounted) {
  return;
}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: green,
          content: Text(
              'Payment ${result['paymentStatus'] ?? 'recorded'}! Remaining: Rs. ${result['remaining']}'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
  return;
}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(errMsg(e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  InputDecoration fieldDecoration({
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF91A3BD)),
      filled: true,
      fillColor: fieldColor,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  Widget fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF394B64),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget groupCard() {
    final group = selectedGroup;
    final name = group?['name']?.toString() ?? 'Select Group';
    final contribution = group?['contribution']?.toString() ?? '0';
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.groups, color: green),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Monthly Contribution',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. $contribution',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final months = List.generate(
      12,
      (index) => DateFormat('yyyy-MM').format(
        DateTime(currentYear, index + 1),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Record Payments',
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadGroups,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      groupCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(17, 35, 17, 38),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFD),
                          border: Border.all(
                            color: const Color(0xFFE1E8F0),
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            fieldLabel('Seettu Group'),
                            DropdownButtonFormField<String>(
                              initialValue: selectedGroupId,
                              isExpanded: true,
                              decoration: fieldDecoration(
                                hint: 'Select Group',
                              ),
                              items: groups.map((group) {
                                return DropdownMenuItem<String>(
                                  value: group['id'].toString(),
                                  child: Text(
                                    group['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  selectedGroupId = value;
                                });
                                loadMembers(value);
                              },
                              validator: (value) =>
                                  value == null ? 'Select a group' : null,
                            ),
                            const SizedBox(height: 25),
                            fieldLabel('Member'),
                            DropdownButtonFormField<String>(
                              key: ValueKey(selectedGroupId),
                              initialValue: selectedMemberId,
                              isExpanded: true,
                              decoration: fieldDecoration(
                                hint: 'Select Member',
                              ),
                              items: members.map((member) {
                                return DropdownMenuItem<String>(
                                  value: member['id'].toString(),
                                  child: Text(
                                    member['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => selectedMemberId = value);
                                loadBalance();
                              },
                              validator: (value) =>
                                  value == null ? 'Select a member' : null,
                            ),
                            const SizedBox(height: 25),
                            paymentProgressCard(),
                            const SizedBox(height: 18),
                            fieldLabel('Payment Amount (Full or Partial)'),
                            TextFormField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              decoration: fieldDecoration(
                                hint: 'Enter amount',
                              ),
                              validator: (value) {
                                final amount =
                                    double.tryParse(value?.trim() ?? '');
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount';
                                }
                                if (remainingBalance != null &&
                                    amount > remainingBalance! + 0.000001) {
                                  return 'Amount exceeds remaining balance';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25),
                            fieldLabel('Payment Month'),
                            DropdownButtonFormField<String>(
                              initialValue: selectedMonth,
                              decoration: fieldDecoration(),
                              items: months.map((month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(formatMonth(month)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedMonth = value);
                                  loadBalance();
                                }
                              },
                            ),
                            const SizedBox(height: 25),
                            fieldLabel('Payment Date'),
                            InkWell(
                              onTap: chooseDate,
                              child: InputDecorator(
                                decoration: fieldDecoration(
                                  suffix: const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(color: ink),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            fieldLabel('Reference / Note (Optional)'),
                            TextFormField(
                              controller: noteController,
                              maxLines: 2,
                              maxLength: 200,
                              decoration: fieldDecoration(
                                hint: 'Cheque No. or payment note...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isLoading ||
                        isSaving ||
                        isBalanceLoading ||
                        loadError != null ||
                        balanceError != null ||
                        remainingBalance == null ||
                        remainingBalance! <= 0
                    ? null
                    : recordPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.maybePop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: fieldColor,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
