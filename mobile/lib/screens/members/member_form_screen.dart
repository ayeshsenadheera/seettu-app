import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../services/mock_data_service.dart';

class MemberFormScreen extends StatefulWidget {
  final String groupId;
  final String? memberId;
  const MemberFormScreen({super.key, required this.groupId, this.memberId});
  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final position = TextEditingController();
  final joinedDate = TextEditingController();
  String status = 'Active';
  Map<String, String> errors = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    joinedDate.text = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (widget.memberId != null) {
      _loadMemberData();
    }
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    final m = await MockDataService.getMemberDetails(widget.groupId, widget.memberId!);
    if (mounted) {
      setState(() {
        name.text = (m['name'] as String?) ?? '';
        phone.text = (m['phone'] as String?) ?? '';
        email.text = (m['email'] as String?) ?? '';
        position.text = (m['position']?.toString()) ?? '';
        status = (m['status'] as String?) ?? 'Active';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate = DateTime.tryParse(joinedDate.text);
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
        joinedDate.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> save() async {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = "Enter the member's full name.";
    if (phone.text.isEmpty) e['phone'] = 'Enter a valid number.';
    final pos = int.tryParse(position.text);
    if (pos == null || pos <= 0) e['position'] = 'Enter a valid position.';
    if (joinedDate.text.isEmpty) e['joinedDate'] = 'Select a joined date.';
    setState(() => errors = e);
    if (e.isNotEmpty) return;

    final data = {
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'position': pos,
      'status': status,
      'joinedAt': joinedDate.text,
    };

    try {
      if (widget.memberId == null) {
        await MockDataService.createMember(widget.groupId, data);
      } else {
        await MockDataService.updateMember(widget.groupId, widget.memberId!, data);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.memberId == null ? 'Member Added Successfully!' : 'Member Updated Successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  Widget _buildField({
    required String label, 
    required TextEditingController controller, 
    String? error, 
    String? placeholder, 
    TextInputType? keyboardType,
    IconData? icon,
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
    final editing = widget.memberId != null;
    return AppScreen(
      title: editing ? 'Edit Member' : 'Add Member',
      children: [
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        else ...[
          Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                editing ? 'Update Member Details' : 'Add New Member',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                editing 
                  ? 'Update the details of this member below.'
                  : 'Enter the new member\'s details to add them to your Seettu group.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
                label: 'Full name', 
                controller: name, 
                error: errors['name'],
                placeholder: 'e.g. Nimal Perera',
                icon: Icons.person_outline,
              ),
              _buildField(
                label: 'Phone number', 
                controller: phone, 
                keyboardType: TextInputType.phone, 
                placeholder: '07X XXX XXXX', 
                error: errors['phone'],
                icon: Icons.phone_outlined,
              ),
              _buildField(
                label: 'Email (optional)', 
                controller: email, 
                keyboardType: TextInputType.emailAddress, 
                error: errors['email'],
                placeholder: 'e.g. name@example.com',
                icon: Icons.email_outlined,
              ),
              _buildField(
                label: 'Position in Seettu', 
                controller: position, 
                keyboardType: TextInputType.number, 
                error: errors['position'],
                placeholder: 'e.g. 1',
                icon: Icons.format_list_numbered_outlined,
              ),
              _buildField(
                label: 'Joined Date', 
                controller: joinedDate, 
                error: errors['joinedDate'],
                placeholder: 'Select date',
                icon: Icons.calendar_month_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              if (editing) ...[
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => status = 'Active'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: status == 'Active' ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: status == 'Active' ? AppColors.primary : AppColors.primary.withOpacity(0.2), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Active',
                            style: TextStyle(
                              color: status == 'Active' ? Colors.white : AppColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => status = 'Inactive'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: status == 'Inactive' ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: status == 'Inactive' ? AppColors.primary : AppColors.primary.withOpacity(0.2), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Inactive',
                            style: TextStyle(
                              color: status == 'Inactive' ? Colors.white : AppColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          title: editing ? 'Save Changes' : 'Add Member', 
          icon: editing ? Icons.check : Icons.person_add_alt_1,
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
