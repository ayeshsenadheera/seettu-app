import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../services/mock_data_service.dart';

class GroupFormScreen extends StatefulWidget {
  final String? id;
  const GroupFormScreen({super.key, this.id});
  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final name = TextEditingController();
  final contribution = TextEditingController();
  final memberLimit = TextEditingController();
  final startDate = TextEditingController();
  final description = TextEditingController();
  String frequency = 'Monthly';
  Map<String, String> errors = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default start date is today
    final today = DateTime.now();
    startDate.text = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (widget.id != null) {
      _loadGroupData();
    }
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    final g = await MockDataService.getGroupDetails(widget.id!);
    if (mounted) {
      setState(() {
        name.text = g['name'] as String;
        contribution.text = g['contribution'].toString();
        memberLimit.text = g['memberLimit'] != null ? g['memberLimit'].toString() : '';
        if (g['startDate'] != null) {
          final d = DateTime.parse(g['startDate'] as String).toLocal();
          startDate.text = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        }
        frequency = (g['frequency'] as String?) ?? 'Monthly';
        description.text = (g['description'] as String?) ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate = DateTime.tryParse(startDate.text);
    if (initialDate == null) initialDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startDate.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> save() async {
    // Pure frontend validation
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'Enter a valid group name.';
    final c = num.tryParse(contribution.text);
    if (c == null || c <= 0) e['contribution'] = 'Enter a valid contribution amount.';
    final n = int.tryParse(memberLimit.text);
    if (n == null || n < 2 || n > 100) e['memberLimit'] = 'Enter a number between 2 and 100.';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(startDate.text) || DateTime.tryParse(startDate.text) == null) {
      e['startDate'] = 'Please select a valid start date.';
    }
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    // Call mock service
    final data = {
      'name': name.text.trim(),
      'contribution': c,
      'memberLimit': n,
      'startDate': startDate.text,
      'frequency': frequency,
      'description': description.text.trim(),
    };

    if (widget.id == null) {
      await MockDataService.createGroup(data);
    } else {
      await MockDataService.updateGroup(widget.id!, data);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.id == null ? 'Group Created Successfully!' : 'Group Updated Successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true); // pass true to indicate success
  }

  Widget _buildField({
    required String label, 
    required TextEditingController controller, 
    String? error, 
    String? placeholder, 
    TextInputType? keyboardType,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: placeholder,
              errorText: error,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.id != null;
    return AppScreen(
      title: editing ? 'Edit Seettu Group' : 'Create Seettu Group',
      children: [
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildField(
                label: 'Group Name',
                controller: name,
                error: errors['name'],
                placeholder: 'e.g. Family Seettu',
                icon: Icons.groups_outlined,
              ),
              
              _buildField(
                label: 'Contribution Amount (Rs.)',
                controller: contribution,
                error: errors['contribution'],
                placeholder: 'e.g. 5000',
                keyboardType: TextInputType.number,
                icon: Icons.attach_money_outlined,
              ),

              const Text(
                'Payment Frequency',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => frequency = 'Weekly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: frequency == 'Weekly' ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: frequency == 'Weekly' ? AppColors.primary : AppColors.primary.withOpacity(0.2), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Weekly',
                          style: TextStyle(
                            color: frequency == 'Weekly' ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => frequency = 'Monthly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: frequency == 'Monthly' ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: frequency == 'Monthly' ? AppColors.primary : AppColors.primary.withOpacity(0.2), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly',
                          style: TextStyle(
                            color: frequency == 'Monthly' ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Number of Members',
                controller: memberLimit,
                error: errors['memberLimit'],
                placeholder: 'e.g. 10',
                keyboardType: TextInputType.number,
                icon: Icons.format_list_numbered_outlined,
              ),

              _buildField(
                label: 'Start Date',
                controller: startDate,
                error: errors['startDate'],
                icon: Icons.calendar_month_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),

              _buildField(
                label: 'Description (Optional)',
                controller: description,
                placeholder: 'Add some details about the group...',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        PrimaryButton(
          title: editing ? 'Save Changes' : 'Create Group', 
          icon: editing ? Icons.check : Icons.add_task,
          onPressed: save,
        ),
        PrimaryButton(
          title: 'Cancel', 
          variant: ButtonVariant.ghost, 
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 20),
        ],
      ],
    );
  }
}
