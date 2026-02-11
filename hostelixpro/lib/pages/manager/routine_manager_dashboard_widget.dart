import 'package:flutter/material.dart';
import 'package:hostelixpro/models/routine.dart';
import 'package:hostelixpro/services/routine_service.dart';
import 'package:hostelixpro/services/dashboard_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/widgets/cards/stat_card.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/data/data_table.dart';
import 'package:intl/intl.dart';

class RoutineManagerDashboardWidget extends StatefulWidget {
  const RoutineManagerDashboardWidget({super.key});

  @override
  State<RoutineManagerDashboardWidget> createState() => _RoutineManagerDashboardWidgetState();
}

class _RoutineManagerDashboardWidgetState extends State<RoutineManagerDashboardWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Routine> _pendingRoutines = [];
  List<Routine> _currentlyOut = [];
  Map<String, dynamic> _stats = {};

  List<dynamic> _alerts = [];
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
        RoutineService.getRoutines(),
        RoutineService.getCurrentlyOut(),
        DashboardService.getRoutineManagerOverview(),
      ]);
      
      final overview = futures[2] as Map<String, dynamic>;
      
      setState(() {
        _pendingRoutines = futures[0] as List<Routine>;
        _currentlyOut = futures[1] as List<Routine>;
        _stats = overview['stats'] ?? {};
        _alerts = overview['alerts'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveRoutine(int id) async {
    try {
      await RoutineService.approveRoutine(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved')),
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
  
  Future<void> _rejectRoutine(int id) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await RoutineService.rejectRoutine(id, reasonController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected')),
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
  }
  
  Future<void> _confirmReturn(int id) async {
    try {
      await RoutineService.confirmReturn(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return confirmed')),
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
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerts Section
            if (_alerts.isNotEmpty) ...[
              ..._alerts.map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(alert['message'] ?? '', style: TextStyle(color: colors.onSurface))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _alerts.remove(alert)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            
            // Live Status Board - Responsive
            isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('In Hostel', '${_stats['in_hostel'] ?? 0}', Icons.home, AppColors.success)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('On Walk', '${_stats['on_walk'] ?? 0}', Icons.directions_walk, AppColors.info)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('On Leave', '${_stats['on_exit'] ?? 0}', Icons.exit_to_app, AppColors.warning)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Pending', '${_stats['pending_requests'] ?? 0}', Icons.pending_actions, AppColors.primary)),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'In Hostel',
                        value: '${_stats['in_hostel'] ?? 0}',
                        icon: Icons.home,
                        iconColor: AppColors.success,
                        trend: 'Students present',
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'On Walk',
                        value: '${_stats['on_walk'] ?? 0}',
                        icon: Icons.directions_walk,
                        iconColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'On Leave',
                        value: '${_stats['on_exit'] ?? 0}',
                        icon: Icons.exit_to_app,
                        iconColor: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        label: 'Pending',
                        value: '${_stats['pending_requests'] ?? 0}',
                        icon: Icons.pending_actions,
                        iconColor: AppColors.primary,
                        trend: (_stats['pending_requests'] ?? 0) > 0 ? 'Action needed' : 'All clear',
                        isPositive: (_stats['pending_requests'] ?? 0) == 0,
                      ),
                    ),
                  ],
                ),
            
            const SizedBox(height: 24),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Pending (${_pendingRoutines.length})'),
                      Tab(text: 'Out (${_currentlyOut.length})'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        isMobile ? _buildMobilePendingList() : _buildPendingTable(),
                        isMobile ? _buildMobileOutList() : _buildCurrentlyOutTable(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.onSurface)),
        ],
      ),
    );
  }
  
  Widget _buildMobilePendingList() {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_pendingRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            const SizedBox(height: 8),
            Text('No pending requests', style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _pendingRoutines.length,
      itemBuilder: (context, index) {
        final routine = _pendingRoutines[index];
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final timeStr = DateFormat('h:mm a').format(date);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceContainerHigh : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        routine.type == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                        size: 18,
                        color: routine.type == 'walk' ? AppColors.info : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(routine.type.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
                    ],
                  ),
                  Text(timeStr, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(routine.studentName ?? 'Student #${routine.studentId}', style: TextStyle(fontSize: 16, color: colors.onSurface)),
              if (routine.payload != null && routine.payload!['reason'] != null && (routine.payload!['reason'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Reason: ${routine.payload!['reason']}', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: colors.onSurfaceVariant)),
                ),
              if (routine.payload != null && routine.payload!['expected_return_time'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Expected Return: ${DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(routine.payload!['expected_return_time']))}', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveRoutine(routine.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRoutine(routine.id),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMobileOutList() {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_currentlyOut.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 48, color: AppColors.success),
            const SizedBox(height: 8),
            Text('All students in hostel', style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _currentlyOut.length,
      itemBuilder: (context, index) {
        final routine = _currentlyOut[index];
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final timeStr = DateFormat('MMM d, h:mm a').format(date);
        final isReturning = routine.status == 'PENDING_RETURN_APPROVAL';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceContainerHigh : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isReturning ? AppColors.info.withValues(alpha: 0.5) : colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        routine.type == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                        size: 18,
                        color: routine.type == 'walk' ? AppColors.info : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(routine.type.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
                    ],
                  ),
                  StatusBadge(label: isReturning ? 'Returning' : 'Out', type: isReturning ? StatusType.info : StatusType.pending),
                ],
              ),
              const SizedBox(height: 8),
              Text(routine.studentName ?? 'Student #${routine.studentId}', style: TextStyle(fontSize: 16, color: colors.onSurface)),
              Text('Left: $timeStr', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              if (routine.payload != null && routine.payload!['reason'] != null && (routine.payload!['reason'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Reason: ${routine.payload!['reason']}', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: colors.onSurfaceVariant)),
                ),
              if (routine.payload != null && routine.payload!['expected_return_time'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Expected Return: ${DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(routine.payload!['expected_return_time']))}', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                ),
              if (isReturning) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmReturn(routine.id),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                    child: const Text('Confirm Return'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPendingTable() {
    if (_pendingRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            const SizedBox(height: 8),
            Text('No pending requests', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return AppDataTable(
      isLoading: _isLoading,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Student')),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Expected Return')),
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _pendingRoutines.map((routine) {
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final timeStr = DateFormat('h:mm a').format(date);
        final reason = routine.payload != null ? routine.payload!['reason'] as String? : null;
        final expectedReturnTime = routine.payload != null ? routine.payload!['expected_return_time'] as int? : null;
        final expectedReturnStr = expectedReturnTime != null ? DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(expectedReturnTime)) : '-';
        
        return DataRow(cells: [
          DataCell(Text('#${routine.id}')),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  routine.type == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(routine.type.toUpperCase()),
              ],
            )
          ),
          DataCell(Text(routine.studentName ?? '#${routine.studentId}')),
          DataCell(Text(reason ?? '-', style: const TextStyle(fontStyle: FontStyle.italic))),
          DataCell(Text(expectedReturnStr)),
          DataCell(Text(timeStr)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _approveRoutine(routine.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _rejectRoutine(routine.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ),
        ]);
      }).toList(),
    );
  }
  
  Widget _buildCurrentlyOutTable() {
    if (_currentlyOut.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 48, color: AppColors.success),
            const SizedBox(height: 8),
            Text('All students are in hostel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    return AppDataTable(
      isLoading: _isLoading,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Student')),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Expected Return')),
        DataColumn(label: Text('Left At')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Action')),
      ],
      rows: _currentlyOut.map((routine) {
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final timeStr = DateFormat('MMM d, h:mm a').format(date);
        final isReturning = routine.status == 'PENDING_RETURN_APPROVAL';
        final reason = routine.payload != null ? routine.payload!['reason'] as String? : null;
        final expectedReturnTime = routine.payload != null ? routine.payload!['expected_return_time'] as int? : null;
        final expectedReturnStr = expectedReturnTime != null ? DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(expectedReturnTime)) : '-';
        
        return DataRow(cells: [
          DataCell(Text('#${routine.id}')),
          DataCell(Text(routine.type.toUpperCase())),
          DataCell(Text(routine.studentName ?? '#${routine.studentId}')),
          DataCell(Text(reason ?? '-', style: const TextStyle(fontStyle: FontStyle.italic))),
          DataCell(Text(expectedReturnStr)),
          DataCell(Text(timeStr)),
          DataCell(StatusBadge(
            label: isReturning ? 'Returning' : 'Out',
            type: isReturning ? StatusType.info : StatusType.pending,
          )),
          DataCell(
            isReturning
              ? ElevatedButton(
                  onPressed: () => _confirmReturn(routine.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Confirm Return'),
                )
              : const Text('-'),
          ),
        ]);
      }).toList(),
    );
  }
}
