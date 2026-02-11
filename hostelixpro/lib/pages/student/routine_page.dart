import 'package:flutter/material.dart';
import 'package:hostelixpro/models/routine.dart';
import 'package:hostelixpro/services/routine_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/cards/stat_card.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/data/data_table.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/auth_provider.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  List<Routine> _routines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });


    try {
      final routines = await RoutineService.getRoutines();
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  // Student actions
  Future<void> _createRequest(String type) async {
    Map<String, dynamic>? payload;

    if (type == 'exit') {
      final result = await _showExitRequestDialog();
      if (result == null) return;
      payload = result;
    }

    try {
      await RoutineService.createRequest(type, payload: payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type request submitted')),
        );
        _loadRoutines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }
  
  Future<Map<String, dynamic>?> _showExitRequestDialog() async {
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final returnDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          
          return AlertDialog(
            title: const Text('Request Exit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Return Time', style: AppTypography.label),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(DateFormat('MMM d, y').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(selectedTime.format(context)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Reason (Optional)', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Why are you leaving?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                   final payload = {
                    'expected_return_time': returnDateTime.millisecondsSinceEpoch,
                    'reason': reasonController.text,
                  };
                  Navigator.pop(context, payload);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _requestReturn(int id) async {
    try {
      await RoutineService.requestReturn(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return reported successfully')),
        );
        _loadRoutines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  // Manager actions
  Future<void> _approveRoutine(int id) async {
    try {
      await RoutineService.approveRoutine(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved')),
        );
        _loadRoutines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        _loadRoutines();
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
    final role = Provider.of<AuthProvider>(context).currentUser?.role;
    final isManager = role == 'routine_manager';

    return AppShell(
      title: isManager ? 'Routine Approvals' : 'Routine Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadRoutines,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Action Buttons - only for students
          if (!isManager) ...[
            LayoutBuilder(builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'New Walk',
                      value: 'Request',
                      icon: Icons.directions_walk,
                      iconColor: AppColors.success,
                      trend: 'Apply for evening walk',
                      onTap: () => _createRequest('walk'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'New Exit',
                      value: 'Request',
                      icon: Icons.exit_to_app,
                      iconColor: AppColors.warning,
                      trend: 'Apply for home leaving',
                      onTap: () => _createRequest('exit'),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
          ],
          
          Text(isManager ? 'Pending Requests' : 'Request History', style: AppTypography.h3),
          const SizedBox(height: 16),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
                    : _routines.isEmpty
                        ? Center(child: Text('No active routines', style: AppTypography.body))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return constraints.maxWidth < 800
                                  ? _buildMobileList(isManager)
                                  : _buildDesktopTable(isManager);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(bool isManager) {
    return AppDataTable(
      columns: [
        if (isManager) const DataColumn(label: Text('ID')),
        const DataColumn(label: Text('Type')),
        const DataColumn(label: Text('Reason')),
        if (isManager) const DataColumn(label: Text('Student')),
        const DataColumn(label: Text('Time')),
        const DataColumn(label: Text('Status')),
        const DataColumn(label: Text('Actions')),
      ],
      rows: _routines.map((routine) {
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final formattedDate = DateFormat('MMM d, h:mm a').format(date);
        
        StatusType statusType = StatusType.pending;
        if (routine.status.contains('APPROVED')) statusType = StatusType.approved;
        if (routine.status.contains('REJECTED')) statusType = StatusType.rejected;
        if (routine.status == 'COMPLETED') statusType = StatusType.info;
        
        final bool isReturn = routine.status == 'PENDING_RETURN_APPROVAL';
        final reason = routine.payload != null ? routine.payload!['reason'] as String? : null;
        
        return DataRow(cells: [
          if (isManager) DataCell(Text('#${routine.id}')),
          DataCell(Row(
            children: [
              Icon(
                routine.type == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(routine.type.toUpperCase()),
            ],
          )),
          DataCell(Text(reason ?? '-', style: const TextStyle(fontStyle: FontStyle.italic))),
          if (isManager) DataCell(Text(routine.studentName ?? routine.studentId.toString())),
          DataCell(Text(formattedDate)),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(
                  label: isReturn ? 'Returning' : routine.status.replaceAll('_', ' '), 
                  type: isReturn ? StatusType.info : statusType,
                ),
                if (routine.status == 'REJECTED' && routine.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      routine.rejectionReason!,
                      style: TextStyle(fontSize: 11, color: AppColors.danger, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          DataCell(
            isManager
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => isReturn ? _confirmReturn(routine.id) : _approveRoutine(routine.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReturn ? AppColors.info : AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(isReturn ? 'Confirm' : 'Approve'),
                    ),
                  ],
                )
              : routine.status == 'APPROVED_PENDING_RETURN'
                ? ElevatedButton(
                    onPressed: () => _requestReturn(routine.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Return'),
                  )
                : const SizedBox(),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildMobileList(bool isManager) {
    return ListView.separated(
      itemCount: _routines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final routine = _routines[index];
        final date = DateTime.fromMillisecondsSinceEpoch(routine.requestTime);
        final formattedDate = DateFormat('MMM d, h:mm a').format(date);
        
        StatusType statusType = StatusType.pending;
        if (routine.status.contains('APPROVED')) statusType = StatusType.approved;
        if (routine.status.contains('REJECTED')) statusType = StatusType.rejected;
        if (routine.status == 'COMPLETED') statusType = StatusType.info;
        
        final bool isReturn = routine.status == 'PENDING_RETURN_APPROVAL';
        final reason = routine.payload != null ? routine.payload!['reason'] as String? : null;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      routine.type == 'walk' ? Icons.directions_walk : Icons.exit_to_app,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      routine.type.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: isReturn ? 'Returning' : routine.status.replaceAll('_', ' '), 
                      type: isReturn ? StatusType.info : statusType,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(formattedDate, style: AppTypography.body),
                  ],
                ),
                if (reason != null && reason.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Reason: $reason',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                if (isManager && routine.studentName != null) ...[
                   const SizedBox(height: 8),
                   Text('Student: ${routine.studentName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
                if (routine.status == 'REJECTED' && routine.rejectionReason != null) ...[
                   const SizedBox(height: 8),
                   Text(
                      'Rejected: ${routine.rejectionReason}',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                ],
                const SizedBox(height: 12),
                if (isManager)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => isReturn ? _confirmReturn(routine.id) : _approveRoutine(routine.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReturn ? AppColors.info : AppColors.success,
                      ),
                      child: Text(isReturn ? 'Confirm Return' : 'Approve Request'),
                    ),
                  ),
                if (!isManager && routine.status == 'APPROVED_PENDING_RETURN')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _requestReturn(routine.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark as Returned'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
