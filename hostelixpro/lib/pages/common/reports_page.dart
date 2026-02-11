import 'package:flutter/material.dart';
import 'package:hostelixpro/models/report.dart';
import 'package:hostelixpro/services/report_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/data/data_table.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/auth_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await ReportService.getReports(status: _filterStatus);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
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
        _loadReports();
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
      await ReportService.rejectReport(id, "Rejected");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report rejected')),
        );
        _loadReports();
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
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isStudent = user?.role == 'student';
    final canApprove = ['teacher', 'admin'].contains(user?.role);

    return AppShell(
      title: 'Daily Reports',
      actions: [
        if (!isStudent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _filterStatus,
                hint: const Text('All Statuses'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'PENDING_TEACHER', child: Text('Pending Teacher')),
                  DropdownMenuItem(value: 'PENDING_ADMIN', child: Text('Pending Admin')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                ],
                onChanged: (val) {
                  setState(() => _filterStatus = val);
                  _loadReports();
                },
                style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface),
                icon: const Icon(Icons.filter_list, size: 18),
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadReports,
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
              : _reports.isEmpty
                  ? Center(child: Text('No reports found', style: AppTypography.body))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return constraints.maxWidth < 800
                            ? _buildMobileList(isStudent, canApprove)
                            : _buildDesktopTable(isStudent, canApprove);
                      },
                    ),
    );
  }

  Widget _buildDesktopTable(bool isStudent, bool canApprove) {
    return AppDataTable(
      columns: [
        const DataColumn(label: Text('ID')),
        if (!isStudent) const DataColumn(label: Text('Student Details')),
        const DataColumn(label: Text('Wake Time')),
        const DataColumn(label: Text('Status')),
        if (canApprove) const DataColumn(label: Text('Actions')),
      ],
      rows: _reports.map((report) {
        final date = DateTime.fromMillisecondsSinceEpoch(report.wakeTime);
        final dateStr = DateFormat('MMM d, y').format(date);
        final timeStr = DateFormat('h:mm a').format(date);
        
        StatusType statusType = StatusType.pending;
        if (report.status.contains('APPROVED')) statusType = StatusType.approved;
        if (report.status.contains('REJECTED')) statusType = StatusType.rejected;
        
        return DataRow(cells: [
          DataCell(Text('#${report.id}')),
          if (!isStudent)
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(report.studentName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${report.studentAdmissionNo ?? '-'} • ${report.studentRoom ?? '-'}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(dateStr, style: AppTypography.caption),
              ],
            ),
          ),
          DataCell(StatusBadge(label: report.status.replaceAll('_', ' '), type: statusType)),
          if (canApprove)
            DataCell(
              report.status.contains('PENDING') 
                ? Row(
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
                  )
                : const SizedBox(),
            ),
        ]);
      }).toList(),
    );
  }

  Widget _buildMobileList(bool isStudent, bool canApprove) {
    return ListView.separated(
      itemCount: _reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = _reports[index];
        final date = DateTime.fromMillisecondsSinceEpoch(report.wakeTime);
        
        StatusType statusType = StatusType.pending;
        if (report.status.contains('APPROVED')) statusType = StatusType.approved;
        if (report.status.contains('REJECTED')) statusType = StatusType.rejected;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${report.id}', style: AppTypography.caption),
                    StatusBadge(label: report.status.replaceAll('_', ' '), type: statusType),
                  ],
                ),
                const SizedBox(height: 8),
                if (!isStudent) ...[
                  Text(
                    report.studentName ?? 'Unknown Student',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${report.studentAdmissionNo ?? '-'} • Room: ${report.studentRoom ?? '-'}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const Divider(height: 16),
                ],
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Wake up at: ${DateFormat('h:mm a').format(date)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(DateFormat('MMM d, y').format(date), style: AppTypography.caption),
                  ],
                ),
                if (canApprove && report.status.contains('PENDING')) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectReport(report.id),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _approveReport(report.id),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
