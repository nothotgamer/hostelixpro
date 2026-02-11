import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostelixpro/services/report_service.dart';
import 'package:hostelixpro/services/routine_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/cards/stat_card.dart';

class StudentDashboardWidget extends StatefulWidget {
  final String userName;

  const StudentDashboardWidget({
    super.key,
    required this.userName,
  });

  @override
  State<StudentDashboardWidget> createState() => _StudentDashboardWidgetState();
}

class _StudentDashboardWidgetState extends State<StudentDashboardWidget> {
  String? _activeStatus;
  String? _activeType;

  @override
  void initState() {
    super.initState();
    _checkActiveStatus();
  }

  Future<void> _checkActiveStatus() async {
    try {
      // Get student's routines to find active one
      // Since specific endpoint for active routine doesn't exist, we fetch latest
      // from list_routines which returns student's own history
      final routines = await RoutineService.getRoutines();
      
      if (routines.isNotEmpty) {
        final latest = routines.first;
        if (['PENDING_ROUTINE_MANAGER', 'APPROVED_PENDING_RETURN', 'PENDING_RETURN_APPROVAL'].contains(latest.status)) {
          if (mounted) {
            setState(() {
              _activeStatus = latest.status;
              _activeType = latest.type;
            });
            return;
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error checking status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Status Banner
        if (_activeStatus != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: _activeStatus == 'PENDING_ROUTINE_MANAGER' 
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _activeStatus == 'PENDING_ROUTINE_MANAGER' 
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _activeType == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                  color: _activeStatus == 'PENDING_ROUTINE_MANAGER' ? AppColors.warning : AppColors.info,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeStatus == 'PENDING_ROUTINE_MANAGER' 
                            ? 'Request Pending' 
                            : _activeStatus == 'PENDING_RETURN_APPROVAL'
                                ? 'Return Approval Pending'
                                : 'Currently Out (${_activeType?.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activeStatus == 'PENDING_ROUTINE_MANAGER'
                            ? 'Your $_activeType request is awaiting manager approval'
                            : _activeStatus == 'PENDING_RETURN_APPROVAL'
                                ? 'You have reported return. Waiting for confirmation.'
                                : 'You are currently marked as out. Don\'t forget to report return.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (_activeStatus == 'APPROVED_PENDING_RETURN')
                  ElevatedButton(
                    onPressed: () => context.push('/routines'),
                    child: const Text('Report Return'),
                  ),
              ],
            ),
          ),
        ],

        Text('Quick Actions', style: AppTypography.h2),
        const SizedBox(height: 16),
        
        LayoutBuilder(builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Daily Report Action
              SizedBox(
                width: isSmall ? double.infinity : (constraints.maxWidth - 32) / 2,
                child: StatCard(
                  label: 'Daily Report',
                  value: 'Mark Up',
                  icon: Icons.alarm,
                  iconColor: AppColors.warning,
                  trend: 'Tap to submit wake-up time',
                  isPositive: true,
                  onTap: () async {
                    try {
                      await ReportService.createDailyReport();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wake up reported successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),

              // Announcements
              SizedBox(
                width: isSmall ? double.infinity : (constraints.maxWidth - 32) / 2,
                child: StatCard(
                  label: 'Announcements',
                  value: 'View All',
                  icon: Icons.campaign,
                  iconColor: AppColors.primary,
                  trend: 'Check latest notices',
                  onTap: () => context.push('/announcements'),
                ),
              ),
              
              // Routines
              SizedBox(
                width: isSmall ? double.infinity : (constraints.maxWidth - 32) / 2,
                child: StatCard(
                  label: 'My Routines',
                  value: 'Manage',
                  icon: Icons.directions_walk,
                  iconColor: AppColors.success,
                  trend: 'Request exit or walk',
                  onTap: () => context.push('/routines'),
                ),
              ),
              
              // Fees
              SizedBox(
                width: isSmall ? double.infinity : (constraints.maxWidth - 32) / 2,
                child: StatCard(
                  label: 'Fee Status',
                  value: 'Check',
                  icon: Icons.attach_money,
                  iconColor: AppColors.info,
                  trend: 'View challans & history',
                  onTap: () => context.push('/fees'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
