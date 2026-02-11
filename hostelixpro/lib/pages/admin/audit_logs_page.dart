import 'package:flutter/material.dart';
import 'package:hostelixpro/models/audit_log.dart';
import 'package:hostelixpro/services/audit_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/forms/form_field.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 50;

  // Filters
  final _actionController = TextEditingController();
  final _entityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await AuditService.getAuditLogs(
        page: _currentPage,
        perPage: _perPage,
        action: _actionController.text,
        entity: _entityController.text,
      );

      setState(() {
        _logs = data['logs'];
        _totalPages = data['pages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() => _currentPage = 1);
    _loadLogs();
  }

  void _clearFilters() {
    _actionController.clear();
    _entityController.clear();
    _applyFilters();
  }

  Color _getActionColor(String action) {
    if (action.contains('DELETE')) return AppColors.danger;
    if (action.contains('CREATE')) return AppColors.success;
    if (action.contains('UPDATE')) return AppColors.info;
    if (action.contains('LOGIN_FAILED')) return AppColors.warning;
    if (action.contains('BLOCK')) return AppColors.danger;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'System Audit Logs',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadLogs,
        ),
      ],
      child: Column(
        children: [
          // Filters
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: ExpansionTile(
              title: Text('Filters', style: AppTypography.h3),
              leading: Icon(Icons.filter_list, color: AppColors.primary),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppFormField(
                          label: 'Action',
                          hint: 'e.g. LOGIN',
                          controller: _actionController,
                          prefixIcon: const Icon(Icons.bolt),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppFormField(
                          label: 'Entity',
                          hint: 'e.g. user',
                          controller: _entityController,
                          prefixIcon: const Icon(Icons.category),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _applyFilters,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
                    : _logs.isEmpty
                        ? Center(child: Text('No logs found', style: AppTypography.body))
                        : ListView.separated(
                            itemCount: _logs.length,
                            separatorBuilder: (c, i) => Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  log.timestamp);
                              
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getActionColor(log.action).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.history,
                                    color: _getActionColor(log.action),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.action,
                                        style: AppTypography.bodyBold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MM/dd HH:mm').format(date),
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(log.details.toString(), style: AppTypography.bodySmall),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          log.userEmail ?? 'System/Anon',
                                          style: AppTypography.caption,
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.monitor, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          log.ip ?? 'Unknown IP',
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
          ),

          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => setState(() {
                              _currentPage--;
                              _loadLogs();
                            })
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages', style: AppTypography.body),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => setState(() {
                              _currentPage++;
                              _loadLogs();
                            })
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
