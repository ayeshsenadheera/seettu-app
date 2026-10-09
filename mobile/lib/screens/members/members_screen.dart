import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';

import '../../services/mock_data_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _selectedGroup;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final groups = await MockDataService.getGroups();
    final String initialGroupId = context.read<AppState>().groupId ?? (groups.isNotEmpty ? groups.first['id'] : '');
    
    List<Map<String, dynamic>> members = [];
    Map<String, dynamic>? selectedGroup;
    
    if (initialGroupId.isNotEmpty) {
      selectedGroup = groups.firstWhere((g) => g['id'] == initialGroupId, orElse: () => groups.first);
      members = await MockDataService.getMembersForGroup(initialGroupId);
    }
    
    if (mounted) {
      setState(() {
        _groups = groups;
        _selectedGroup = selectedGroup;
        _members = members;
        _isLoading = false;
      });
    }
  }

  Future<void> _onGroupSelected(String groupId) async {
    setState(() => _isLoading = true);
    context.read<AppState>().setGroupId(groupId);
    
    final members = await MockDataService.getMembersForGroup(groupId);
    final selectedGroup = _groups.firstWhere((g) => g['id'] == groupId, orElse: () => _groups.first);
    
    if (mounted) {
      setState(() {
        _selectedGroup = selectedGroup;
        _members = members;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScreen(
        title: 'Member List',
        back: false,
        children: [
           Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        ],
      );
    }

    final group = _selectedGroup!;
    final members = _members;

    return AppScreen(
      title: 'Member List',
      back: false,
      footer: PrimaryButton(
        title: 'Add New Member',
        icon: Icons.person_add_alt_1,
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/member-form', arguments: {'groupId': group['id']});
          if (result == true) _onGroupSelected(group['id'] as String);
        },
      ),
      children: [
        GroupPickerBar(
          groups: _groups, 
          group: group, 
          onSelect: _onGroupSelected
        ),
        const SizedBox(height: 16),

        // Beautiful Summary Dashboard
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '${members.length}', Icons.people_alt_rounded),
              _buildDivider(),
              _buildStatItem('Active', '${members.where((m) => m['status'] == 'Active').length}', Icons.verified_user_rounded),
              _buildDivider(),
              _buildStatItem('Next', members.firstWhere((m) => m['nextPayout'] == true, orElse: () => {'name': '-'})['name'].toString().split(' ')[0], Icons.star_rounded),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Members', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${members.length} / 10',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (members.isEmpty)
          const EmptyBox(text: 'No members yet. Add someone!')
        else
          ...members.map((m) {
            final isActive = m['status'] == 'Active';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    await Navigator.of(context).pushNamed('/member-details', arguments: {'groupId': group['id'], 'memberId': m['id']});
                    _onGroupSelected(group['id'] as String);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Large Avatar
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryLight.withOpacity(0.6) : AppColors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.mute.withOpacity(0.2), width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials(m['name'] as String),
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.w900, 
                              color: isActive ? AppColors.primary : AppColors.mute,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Bigger Details (Using Wrap to prevent overflow)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Text(
                                m['name'] as String, 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive ? Icons.verified : Icons.cancel, 
                                        size: 14, 
                                        color: isActive ? AppColors.primary : AppColors.mute,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        m['status'] as String, 
                                        style: TextStyle(fontSize: 13, color: isActive ? AppColors.primary : AppColors.mute, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '•', 
                                    style: TextStyle(fontSize: 13, color: AppColors.mute.withOpacity(0.5), fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Pos #${m['position']}', 
                                    style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.mute),
                                      const SizedBox(width: 4),
                                      Text(
                                        m['phone'] as String, 
                                        style: const TextStyle(fontSize: 12, color: AppColors.mute, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mute),
                                      const SizedBox(width: 4),
                                      Text(
                                        (m['joined'] as String?) ?? 'N/A', 
                                        style: const TextStyle(fontSize: 12, color: AppColors.mute, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Next Payout Tag
                        if (m['nextPayout'] == true) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.orangeLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: AppColors.orange, size: 20),
                                SizedBox(height: 2),
                                Text(
                                  'Next', 
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.orange),
                                ),
                              ],
                            ),
                          )
                        else 
                          const Icon(Icons.chevron_right, color: AppColors.mute, size: 28),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
