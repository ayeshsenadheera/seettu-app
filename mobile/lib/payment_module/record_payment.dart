import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  final amountController = TextEditingController(text: '10000');

  final members = [
    'Heshan',
    'Ayesh',
    'Diyana',
    'Nimal',
    'Kasun',
    'Amal',
    'Sahan',
    'Kavindu',
  ];

  String? selectedMember;
  late String selectedMonth;
  DateTime paymentDate = DateTime(2026, 9, 25);

  @override
  void initState() {
    super.initState();
    selectedMonth = '2026-09';
  }

  @override
  void dispose() {
    noteController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(paymentDate);

  String formatMonth(String month) {
    final date = DateTime.parse('$month-01');
    return DateFormat('MMMM yyyy').format(date);
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() => paymentDate = selected);
    }
  }

  void recordPayment() {
    if (!formKey.currentState!.validate()) return;

    final amount = double.parse(amountController.text);

    // Frontend preview only. No payment is saved to the backend.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: green,
        content: Text(
          'Demo payment recorded: $selectedMember - Rs. ${amount.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  InputDecoration fieldDecoration({String? hint, Widget? suffix}) {
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
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.groups, color: green),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Friend Seettu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Monthly Contribution',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'Rs. 10,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      12,
      (index) {
        final month = DateTime(2026, index + 1);
        return DateFormat('yyyy-MM').format(month);
      },
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Form(
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
                border: Border.all(color: const Color(0xFFE1E8F0)),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Member'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMember,
                    decoration: fieldDecoration(
                      hint: 'Select Member',
                    ),
                    items: members
                        .map(
                          (member) => DropdownMenuItem(
                            value: member,
                            child: Text(member),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedMember = value),
                    validator: (value) =>
                        value == null ? 'Please select a member' : null,
                  ),
                  const SizedBox(height: 25),
                  fieldLabel('Contribution Amount'),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: fieldDecoration(hint: 'Enter amount'),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  fieldLabel('Payment Month'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMonth,
                    decoration: fieldDecoration(),
                    items: months
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(formatMonth(month)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMonth = value);
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
                      hint: 'UPI Ref, Cheque No, or payment note...',
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
                onPressed: recordPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
                onPressed: () => Navigator.maybePop(context),
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
