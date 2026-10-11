import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'payment_service.dart';

class SharedPaymentRecordsScreen extends StatefulWidget {
  const SharedPaymentRecordsScreen({super.key});

  @override
  State<SharedPaymentRecordsScreen> createState() =>
      _SharedPaymentRecordsScreenState();
}

class _SharedPaymentRecordsScreenState
    extends State<SharedPaymentRecordsScreen> {
  static const Color green = Color(0xFF078653);
  static const Color dark = Color(0xFF172238);
  static const Color muted = Color(0xFF8EA1BE);
  static const Color border = Color(0xFFE3EAF2);

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic> summary = {};
  String? selectedGroupId;
  String? error;
  bool loadingGroups = true;
  bool loadingRecords = false;
  late DateTime selectedMonth;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    _loadGroups();
  }

  String get monthKey =>
      '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';

  String get monthName {
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
    return '${names[selectedMonth.month - 1]} ${selectedMonth.year}';
  }

  String _text(dynamic value, [String fallback = '']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _integer(dynamic value) => _number(value).toInt();

  String _money(dynamic amount) {
    final value = _number(amount);
    final fixed = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    final pieces = fixed.split('.');
    final whole = pieces.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Rs. $whole${pieces.length == 2 ? '.${pieces[1]}' : ''}';
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  Map<String, dynamic>? get selectedGroup {
    for (final group in groups) {
      if (_text(group['id'] ?? group['_id']) == selectedGroupId) return group;
    }
    return null;
  }

  Future<void> _loadGroups() async {
    setState(() {
      loadingGroups = true;
      error = null;
    });
    try {
      final response = await api.get('/groups');
      final loaded = _list(response['groups']);

      setState(() {
        groups = loaded;
        selectedGroupId = loaded.isEmpty
            ? null
            : _text(loaded.first['id'] ?? loaded.first['_id']);
        loadingGroups = false;
      });
      if (selectedGroupId != null) await _loadRecords();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = errMsg(e);
        loadingGroups = false;
      });
    }
  }

  Future<void> _loadRecords() async {
    final groupId = selectedGroupId;
    if (groupId == null) return;
    final requestId = ++_requestId;
    setState(() {
      loadingRecords = true;
      error = null;
    });
    try {
      final result = await paymentService.getSharedRecords(
        groupId: groupId,
        month: monthKey,
      );
      if (!mounted || requestId != _requestId || selectedGroupId != groupId) {
        return;
      }
      final loaded =
          _list(result['records'] ?? result['members'] ?? result['payments']);
      final suppliedSummary = _map(result['summary']);
      setState(() {
        records = loaded;
        summary = suppliedSummary;
        loadingRecords = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId || selectedGroupId != groupId) {
        return;
      }
      setState(() {
        error = errMsg(e);
        loadingRecords = false;
      });
    }
  }

  void _selectGroup(String? id) {
    if (id == null || id == selectedGroupId) return;
    ++_requestId;
    setState(() {
      selectedGroupId = id;
      records = [];
      summary = {};
      error = null;
    });
    _loadRecords();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select payment month',
    );
    if (picked == null || !mounted) return;
    if (picked.year == selectedMonth.year &&
        picked.month == selectedMonth.month) {
      return;
    }
    ++_requestId;
    setState(() {
      selectedMonth = DateTime(picked.year, picked.month);
      records = [];
      summary = {};
      error = null;
    });
    _loadRecords();
  }

  String _status(Map<String, dynamic> member) {
    final raw = _text(member['status'] ?? member['paymentStatus'], 'Pending');
    final normalized = raw.toLowerCase();
    if (normalized == 'paid' || normalized == 'fully paid') return 'Paid';
    if (normalized == 'partial' || normalized == 'partially paid') {
      return 'Partial';
    }
    if (normalized == 'late') return 'Late';
    if (normalized == 'missed') return 'Missed';
    return 'Pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return green;
      case 'Partial':
        return const Color(0xFF2477C5);
      case 'Late':
        return const Color(0xFFE37C00);
      case 'Missed':
        return const Color(0xFFF04460);
      default:
        return const Color(0xFF9A6C18);
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFFE9FFF3);
      case 'Partial':
        return const Color(0xFFEAF4FF);
      case 'Late':
        return const Color(0xFFFFF3E5);
      case 'Missed':
        return const Color(0xFFFFEDF0);
      default:
        return const Color(0xFFFFF8E5);
    }
  }

  int _count(String status) =>
      records.where((r) => _status(r) == status).length;

  int _summaryCount(String key, int fallback) =>
      summary.containsKey(key) ? _integer(summary[key]) : fallback;

  String _dateLabel(dynamic value) {
    final text = _text(value);
    if (text.isEmpty) return '';
    final date = DateTime.tryParse(text);
    if (date == null) return text;
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${names[date.month - 1]} ${date.year}';
  }

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
                child: loadingGroups
                    ? const Center(
                        child: CircularProgressIndicator(color: green))
                    : error != null && groups.isEmpty
                        ? _errorView(_loadGroups)
                        : groups.isEmpty
                            ? const Center(
                                child: Text('No Seettu groups found.'))
                            : RefreshIndicator(
                                onRefresh: _loadRecords,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 18, 18, 12),
                                  children: [
                                    _groupCard(),
                                    const SizedBox(height: 18),
                                    _monthCard(),
                                    const SizedBox(height: 18),
                                    _summaryCard(),
                                    const SizedBox(height: 24),
                                    _contributionHeader(),
                                    const SizedBox(height: 12),
                                    if (loadingRecords)
                                      const Padding(
                                        padding: EdgeInsets.all(36),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: green)),
                                      )
                                    else if (error != null)
                                      _errorView(_loadRecords)
                                    else if (records.isEmpty)
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 36),
                                        child: Center(
                                            child: Text(
                                                'No member records found for this month.',
                                                style:
                                                    TextStyle(color: muted))),
                                      )
                                    else
                                      ...records.map(_memberCard),
                                  ],
                                ),
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
          border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: dark),
          ),
          const Expanded(
            child: Text('Shared Payment Records',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: dark, fontSize: 19, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadingRecords ? null : _loadRecords,
            icon: const Icon(Icons.refresh, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _groupCard() {
    final group = selectedGroup;
    final id = selectedGroupId;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF078653), Color(0xFF008263)]),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22007850), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.groups_outlined, color: green, size: 29),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: id,
                    isExpanded: true,
                    dropdownColor: green,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                    items: groups
                        .map((g) => DropdownMenuItem<String>(
                              value: _text(g['id'] ?? g['_id']),
                              child: Text(_text(g['name'], 'Unnamed Group'),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _selectGroup,
                  ),
                ),
                const SizedBox(height: 5),
                const Text('Monthly Contribution',
                    style: TextStyle(color: Color(0xFFC2E8D9), fontSize: 12)),
                const SizedBox(height: 5),
                Text(_money(group?['contribution']),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthCard() {
    return InkWell(
      onTap: _pickMonth,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_outlined, color: green, size: 20),
            const SizedBox(width: 9),
            Text(monthName,
                style: const TextStyle(
                    color: dark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 9),
            const Icon(Icons.keyboard_arrow_down, color: dark),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _summaryCount('totalMembers', records.length);
    final paid = _summaryCount('paid', _count('Paid'));
    final partial = _summaryCount('partial', _count('Partial'));
    final pending = _summaryCount('pending', _count('Pending'));
    final late = _summaryCount('late', _count('Late'));
    final missed = _summaryCount('missed', _count('Missed'));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(children: [
            _summaryItem('Total\nMembers', '$total', dark),
            _verticalDivider(),
            _summaryItem('Paid', '$paid', green),
            _verticalDivider(),
            _summaryItem('Partial', '$partial', const Color(0xFF2477C5)),
          ]),
          const SizedBox(height: 16),
          const Divider(color: border, height: 1),
          const SizedBox(height: 16),
          Row(children: [
            _summaryItem('Pending', '$pending', const Color(0xFF9A6C18)),
            _verticalDivider(),
            _summaryItem('Late', '$late', const Color(0xFFE37C00)),
            _verticalDivider(),
            _summaryItem('Missed', '$missed', const Color(0xFFF04460)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String count, Color color) {
    return Expanded(
      child: Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF667B99),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 9),
        Text(count,
            style: TextStyle(
                color: color, fontSize: 25, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _verticalDivider() => Container(height: 53, width: 1, color: border);

  Widget _contributionHeader() {
    final paid = _summaryCount('paid', _count('Paid'));
    final total = _summaryCount('totalMembers', records.length);
    return Row(children: [
      const Expanded(
          child: Text('MEMBER CONTRIBUTIONS',
              style: TextStyle(
                  color: Color(0xFF667B99),
                  fontSize: 13,
                  fontWeight: FontWeight.bold))),
      Text('$paid of $total Completed',
          style: const TextStyle(
              color: green, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final status = _status(member);
    final contribution =
        _number(member['contribution'] ?? selectedGroup?['contribution']);
    final paid = _number(
        member['paidAmount'] ?? member['totalPaid'] ?? member['amountPaid']);
    final remaining = _number(member['remaining'] ??
        member['remainingAmount'] ??
        (contribution - paid).clamp(0, double.infinity));
    final date = _dateLabel(
        member['lastPaymentDate'] ?? member['paidOn'] ?? member['date']);
    final name =
        _text(member['memberName'] ?? member['name'], 'Unknown Member');
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: border)),
          child: const Icon(Icons.person, color: Color(0xFF70829E), size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: dark, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_money(paid)} / ${_money(contribution)} paid',
              style: const TextStyle(
                  color: Color(0xFF384860),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Remaining: ${_money(remaining)}',
              style: const TextStyle(color: muted, fontSize: 12)),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Last paid on $date',
                style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ])),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _statusBackground(status),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _statusColor(status).withValues(alpha: 0.25)),
          ),
          child: Text(status,
              style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _errorView(Future<void> Function() retry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: retry, child: const Text('Try Again')),
      ]),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(top: BorderSide(color: border))),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFE5EAF2),
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('CANCEL',
              style: TextStyle(
                  color: dark, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
