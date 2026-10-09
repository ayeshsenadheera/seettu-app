import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../services/mock_data_service.dart';

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

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await MockDataService.getGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'My Seettu Groups',
      back: false,
      footer: PrimaryButton(
        title: 'Add New Group',
        icon: Icons.add_circle_outline,
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/group-form');
          if (result == true) {
            setState(() => _isLoading = true);
            _loadGroups();
          }
        },
      ),
      children: [
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        else if (_groups.isEmpty)
          const EmptyBox(text: 'You have no groups yet. Tap Add Group to start your first seettu.')
        else
          ..._groups.map((g) {
            final memberCount = (g['memberCount'] as num).toInt();
            final memberLimit = (g['memberLimit'] as num?)?.toInt() ?? 10;
            final nextCol = _getNextCollection(g['startDate'] as String, g['frequency'] as String);
            
            return GestureDetector(
              onTap: () async {
                await Navigator.of(context).pushNamed('/group-details', arguments: g['id']);
                // Always reload in case of edits
                if (mounted) {
                  setState(() => _isLoading = true);
                  _loadGroups();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Group Icon / Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (g['name'] as String)[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Group Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g['name'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primaryDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$memberCount / $memberLimit Members',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: AppColors.mute)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mute),
                                  const SizedBox(width: 4),
                                  Text(
                                    g['frequency'] as String,
                                    style: const TextStyle(fontSize: 13, color: AppColors.mute),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contribution',
                              style: TextStyle(fontSize: 12, color: AppColors.mute),
                            ),
                            Text(
                              'Rs. ${g['contribution']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Next Collection',
                              style: TextStyle(fontSize: 12, color: AppColors.mute),
                            ),
                            Text(
                              fmtDate(nextCol.toIso8601String()),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
      ],
    );
  }
}
