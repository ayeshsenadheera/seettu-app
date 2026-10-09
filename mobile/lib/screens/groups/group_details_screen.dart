import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/mock_data_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String id;
  const GroupDetailsScreen({super.key, required this.id});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  Map<String, dynamic>? _group;
  bool _isLoading = true;

  DateTime _getNextCollection(String startDateStr, String frequency) {
    final start = DateTime.parse(startDateStr).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime next = DateTime(start.year, start.month, start.day);
    
    if (frequency == 'Weekly') {
      while (next.compareTo(today) <= 0) {
        next = next.add(const Duration(days: 7));
      }
    } else {
      while (next.compareTo(today) <= 0) {
        int nextMonth = next.month + 1;
        int nextYear = next.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        next = DateTime(nextYear, nextMonth, start.day);
      }
    }
    return next;
  }

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final g = await MockDataService.getGroupDetails(widget.id);
    if (mounted) {
      setState(() {
        _group = g;
        _isLoading = false;
      });
    }
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              setState(() => _isLoading = true);
              await MockDataService.deleteGroup(widget.id);
              if (!mounted) return;
              Navigator.of(context).pop(true); // Return true to trigger refresh
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Group deleted successfully!'),
                backgroundColor: AppColors.red,
              ));
            }, 
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mute),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.mute, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _group == null) {
      return const AppScreen(
        title: 'Group Details',
        children: [
          Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        ],
      );
    }

    final g = _group!;
    final contribution = (g['contribution'] as num?)?.toInt() ?? 0;
    final memberLimit = (g['memberLimit'] as num?)?.toInt() ?? 10;
    final memberCount = (g['memberCount'] as num?)?.toInt() ?? 0;

    final totalPayout = contribution * memberLimit;
    final isFull = memberCount >= memberLimit;

    return AppScreen(
      title: 'Group Details',
      children: [
        // Top Highlight Card (Total Payout)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withBlue(150)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_rounded, color: Colors.white70, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    g['name'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Total Payout Pool',
                style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. $totalPayout',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFull ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: isFull ? Colors.greenAccent : Colors.orangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFull ? 'Group is Full' : 'Needs more members',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Quick Stats Row
        Row(
          children: [
            _buildStatCard(
              'Contribution', 
              'Rs. $contribution', 
              Icons.payments_rounded, 
              Colors.orange
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Members', 
              '$memberCount / $memberLimit', 
              Icons.people_alt_rounded, 
              Colors.blue
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Details List
        const Text(
          'More Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
          ),
          child: Column(
            children: [
              _buildDetailRow('Frequency', g['frequency'] as String? ?? 'Monthly', Icons.repeat_rounded),
              Divider(color: AppColors.primary.withOpacity(0.05), height: 1, thickness: 1),
              _buildDetailRow('Start Date', g['startDate'] != null ? fmtDate(g['startDate'] as String) : 'TBD', Icons.play_circle_filled_rounded),
              Divider(color: AppColors.primary.withOpacity(0.05), height: 1, thickness: 1),
              _buildDetailRow('Next Payment', g['startDate'] != null ? fmtDate(_getNextCollection(g['startDate'] as String, g['frequency'] as String? ?? 'Monthly').toIso8601String()) : 'TBD', Icons.event_available_rounded),
              
              if ((g['description'] as String?)?.isNotEmpty == true) ...[
                Divider(color: AppColors.primary.withOpacity(0.05), height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 14, color: AppColors.mute, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              g['description'] as String,
                              style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Action Buttons
        PrimaryButton(
          title: 'Edit Group Settings',
          icon: Icons.edit_rounded,
          onPressed: () async {
            final result = await Navigator.of(context).pushNamed('/group-form', arguments: widget.id);
            if (result == true) {
              setState(() => _isLoading = true);
              _loadGroup();
            }
          },
        ),
        PrimaryButton(
          title: 'Delete Group',
          icon: Icons.delete_outline_rounded,
          variant: ButtonVariant.dangerSolid,
          onPressed: () => _delete(context),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
