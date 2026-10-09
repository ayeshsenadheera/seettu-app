import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

import '../../services/mock_data_service.dart';

class MemberDetailsScreen extends StatefulWidget {
  final String groupId;
  final String memberId;
  const MemberDetailsScreen({super.key, required this.groupId, required this.memberId});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  Map<String, dynamic>? _member;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    final m = await MockDataService.getMemberDetails(widget.groupId, widget.memberId);
    if (mounted) {
      setState(() {
        _member = m;
        _isLoading = false;
      });
    }
  }

  void _remove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('They will be removed from this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await MockDataService.deleteMember(widget.groupId, widget.memberId);
              if (!mounted) return;
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed successfully!')));
            }, 
            child: const Text('Remove', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _member == null) {
      return const AppScreen(
        title: 'Member Details',
        children: [
          Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        ],
      );
    }

    final m = _member!;
    final isActive = m['status'] == 'Active';

    return AppScreen(
      title: 'Member Details',
      children: [
        // Beautiful Header Profile
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withOpacity(0.15) : AppColors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.mute.withOpacity(0.3), width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials(m['name'] as String),
                  style: TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.w900, 
                    color: isActive ? AppColors.primary : AppColors.mute
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                m['name'] as String,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.mute,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: (isActive ? AppColors.primary : AppColors.mute).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.verified : Icons.cancel, 
                      color: Colors.white, size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (m['status'] as String).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Beautiful Details Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 6)),
            ],
            border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
          ),
          child: Column(
            children: [
              _buildDetailRow(Icons.phone_rounded, 'Phone Number', m['phone'] as String),
              _buildDivider(),
              _buildDetailRow(Icons.email_rounded, 'Email Address', (m['email'] as String?) ?? 'Not provided'),
              _buildDivider(),
              _buildDetailRow(Icons.format_list_numbered_rounded, 'Payout Position', '#${m['position']}'),
              _buildDivider(),
              _buildDetailRow(Icons.calendar_month_rounded, 'Payout Date', m['payoutDate'] != null ? fmtDate(m['payoutDate'] as String) : 'TBD'),
            ],
          ),
        ),
        
        const SizedBox(height: 28),
        
        PrimaryButton(
          title: 'Edit Member Details',
          icon: Icons.edit_rounded,
          onPressed: () async {
            final result = await Navigator.of(context).pushNamed('/member-form', arguments: {'groupId': widget.groupId, 'memberId': widget.memberId});
            if (result == true) {
              setState(() => _isLoading = true);
              _loadMember();
            }
          },
        ),
        PrimaryButton(
          title: 'Remove from Group', 
          icon: Icons.person_remove_rounded, 
          variant: ButtonVariant.dangerSolid, 
          onPressed: () => _remove(context)
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.mute, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.primary.withOpacity(0.08),
    );
  }
}
