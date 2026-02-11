import 'package:flutter/material.dart';
import 'package:hostelixpro/models/report.dart';
import 'package:hostelixpro/services/report_service.dart';
import 'package:hostelixpro/services/dashboard_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/cards/stat_card.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/data/data_table.dart';
import 'package:intl/intl.dart';

class TeacherDashboardWidget extends StatefulWidget {
  const TeacherDashboardWidget({super.key});

  @override
  State<TeacherDashboardWidget> createState() => _TeacherDashboardWidgetState();
}

class _TeacherDashboardWidgetState extends State<TeacherDashboardWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Report> _pendingReports = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _dailyData = {};
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        ReportService.getReports(status: 'pending_teacher'),
        DashboardService.getStats(),
        DashboardService.getTeacherStudentsDaily(),
      ]);

      if (mounted) {
        setState(() {
          _pendingReports = futures[0] as List<Report>;
          _stats = futures[1] as Map<String, dynamic>;
          _dailyData = futures[2] as Map<String, dynamic>;
          _students = _dailyData['students'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveReport(int id) async {
    try {
      await ReportService.approveReport(id);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report approved')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectReport(int id) async {
    try {
      await ReportService.rejectReport(id, "Rejected by teacher");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report rejected')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = _dailyData['summary'] as Map<String, dynamic>? ?? {};
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Section
        Row(
           children: [
             Expanded(
               child: StatCard(
                label: 'Pending Reports',
                value: '${_stats['pending_reports'] ?? 0}',
                icon: Icons.assignment_late,
                iconColor: AppColors.warning,
                trend: _pendingReports.isNotEmpty ? 'Action required' : 'All clear',
                isPositive: _pendingReports.isEmpty,
              ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: StatCard(
                label: 'Assigned Students',
                value: '${_stats['total_students'] ?? 0}',
                icon: Icons.people,
                iconColor: AppColors.primary,
                trend: '${summary['reported_today'] ?? 0} reported today',
              ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: StatCard(
                label: 'Attendance Rate',
                value: '${_stats['attendance_rate'] ?? 0}%',
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                trend: (_stats['attendance_rate'] ?? 0) >= 90 ? 'Excellent' : 'Needs attention',
                isPositive: (_stats['attendance_rate'] ?? 0) >= 90,
              ),
             ),
           ],
        ),
        
        const SizedBox(height: 24),
        
        // Tabs
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Daily Reports (${_pendingReports.length})'),
            Tab(text: 'My Students (${_students.length})'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportsTab(),
              _buildStudentsTab(colors),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildReportsTab() {
    if (_pendingReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
              const SizedBox(height: 8),
              Text('No pending reports', style: AppTypography.bodySecondary),
            ],
          ),
        ),
      );
    }
    
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Report ID')),
        DataColumn(label: Text('Student')),
        DataColumn(label: Text('Wake Time')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _pendingReports.map((report) {
        final date = DateTime.fromMillisecondsSinceEpoch(report.wakeTime);
        final timeStr = DateFormat('MMM d, h:mm a').format(date);
        
        return DataRow(cells: [
          DataCell(Text('#${report.id}')),
          DataCell(Text(report.studentId.toString())),
          DataCell(Text(timeStr)),
          DataCell(StatusBadge(label: 'Pending', type: StatusType.pending)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: () => _approveReport(report.id),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger),
                  onPressed: () => _rejectReport(report.id),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ),
        ]);
      }).toList(),
    );
  }
  
  Widget _buildStudentsTab(ColorScheme colors) {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('No students assigned', style: AppTypography.bodySecondary),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return _StudentStatusCard(student: student);
      },
    );
  }
}

class _StudentStatusCard extends StatelessWidget {
  final Map<String, dynamic> student;
  
  const _StudentStatusCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final name = student['name'] ?? 'Unknown';
    final roomNo = student['room_no'] ?? '-';
    final wakeReported = student['wake_reported'] ?? false;
    final currentStatus = student['current_status'] ?? 'in_hostel';
    final feeStatus = student['fee_status'] ?? 'paid';
    
    Color statusColor = AppColors.success;
    String statusLabel = 'In Hostel';
    IconData statusIcon = Icons.home;
    
    switch (currentStatus) {
      case 'on_walk':
        statusColor = AppColors.info;
        statusLabel = 'On Walk';
        statusIcon = Icons.directions_walk;
        break;
      case 'on_exit':
        statusColor = AppColors.warning;
        statusLabel = 'On Leave';
        statusIcon = Icons.exit_to_app;
        break;
      case 'pending_exit':
        statusColor = AppColors.secondary;
        statusLabel = 'Pending Exit';
        statusIcon = Icons.hourglass_empty;
        break;
    }
    
    return Card(
      color: isDark ? colors.surfaceContainerHigh : colors.surface,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Room: $roomNo',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusChip(
                  icon: statusIcon,
                  label: statusLabel,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Icon(
                  wakeReported ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: wakeReported ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  wakeReported ? 'Reported' : 'Not Reported',
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            if (feeStatus != 'paid') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (feeStatus == 'overdue' ? AppColors.danger : AppColors.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  feeStatus == 'overdue' ? '⚠ Fee Overdue' : '⏳ Fee Pending',
                  style: TextStyle(
                    fontSize: 10,
                    color: feeStatus == 'overdue' ? AppColors.danger : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

