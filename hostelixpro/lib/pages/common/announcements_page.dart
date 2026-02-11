import 'package:flutter/material.dart';
import 'package:hostelixpro/models/announcement.dart';
import 'package:hostelixpro/providers/auth_provider.dart';
import 'package:hostelixpro/services/announcement_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/forms/form_field.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() => _isLoading = true);
      final data = await AnnouncementService.getAnnouncements();
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    try {
      await AnnouncementService.deleteAnnouncement(id);
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateAnnouncementDialog(),
    ).then((created) {
      if (created == true) _loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final canCreate = user != null && 
        ['admin', 'teacher', 'routine_manager'].contains(user.role);
    final canDelete = user != null && user.role == 'admin';

    return AppShell(
      title: 'Announcements',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAnnouncements,
        ),
        if (canCreate)
          FloatingActionButton.small(
            onPressed: _showCreateDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
              : _announcements.isEmpty
                  ? Center(child: Text('No announcements yet', style: AppTypography.body))
                  : ListView.builder(
                      itemCount: _announcements.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        return _AnnouncementCard(
                          announcement: announcement,
                          canDelete: canDelete,
                          onDelete: () => _deleteAnnouncement(announcement.id),
                        );
                      },
                    ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool canDelete;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = announcement.priority == 'critical';
    final isHoliday = announcement.announcementType == 'holiday';
    final isEvent = announcement.announcementType == 'event';
    
    final date = DateTime.fromMillisecondsSinceEpoch(announcement.createdAt);
    DateTime? eventDate;
    if (announcement.eventDate != null) {
      try {
        eventDate = DateFormat('yyyy-MM-dd').parse(announcement.eventDate!);
      } catch (e) {
        // ignore invalid date
      }
    }
    
    final borderColor = isCritical 
        ? AppColors.danger.withValues(alpha: 0.5) 
        : isHoliday 
            ? Colors.orange.withValues(alpha: 0.5)
            : isEvent
                ? Colors.blue.withValues(alpha: 0.5)
                : AppColors.border;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                         children: [
                           if (isCritical) ...[
                             Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
                             const SizedBox(width: 8),
                           ] else if (isHoliday) ...[
                             const Icon(Icons.celebration, color: Colors.orange, size: 20),
                             const SizedBox(width: 8),
                           ] else if (isEvent) ...[
                             const Icon(Icons.event, color: Colors.blue, size: 20),
                             const SizedBox(width: 8),
                           ],
                           Expanded(child: Text(announcement.title, style: AppTypography.h3)),
                         ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posted by ${announcement.authorName} • ${DateFormat.yMMMd().format(date)}',
                        style: AppTypography.caption,
                      ),
                      if (eventDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${isHoliday ? "Holiday" : "Event"}: ${
                                  announcement.eventDate != null && announcement.endDate != null 
                                    ? "${DateFormat.yMMMEd().format(eventDate)} - ${DateFormat.yMMMEd().format(DateTime.parse(announcement.endDate!))}"
                                    : DateFormat.yMMMEd().format(eventDate)
                                }',
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (announcement.priority != 'normal' && !isHoliday)
                  StatusBadge(
                    label: announcement.priority.toUpperCase(),
                    type: isCritical ? StatusType.rejected : StatusType.warning,
                  ),
                if (canDelete)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              announcement.content,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAnnouncementDialog extends StatefulWidget {
  const CreateAnnouncementDialog({super.key});

  @override
  State<CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<CreateAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _priority = 'normal';
  String? _targetRole;
  String _announcementType = 'general';
  DateTime? _eventDate;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _eventDate != null 
          ? DateTimeRange(start: _eventDate!, end: _endDate ?? _eventDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked.start;
        // Only set end date if it's different from start date
        _endDate = picked.start.isAtSameMomentAs(picked.end) ? null : picked.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Require date for holiday/event types
    if ((_announcementType == 'holiday' || _announcementType == 'event') && _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range for this holiday/event')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? eventDateStr;
      String? endDateStr;
      
      if (_eventDate != null) {
        eventDateStr = DateFormat('yyyy-MM-dd').format(_eventDate!);
      }
      if (_endDate != null) {
        endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      
      await AnnouncementService.createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        priority: _announcementType == 'holiday' ? 'high' : _priority,
        targetRole: _targetRole,
        announcementType: _announcementType,
        eventDate: eventDateStr,
        endDate: endDateStr,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    String dateText = 'Select dates...';
    if (_eventDate != null) {
      final start = DateFormat('MMM d').format(_eventDate!);
      if (_endDate != null) {
        final end = DateFormat('MMM d, yyyy').format(_endDate!);
        dateText = '$start - $end';
      } else {
        dateText = DateFormat('EEEE, MMMM d, yyyy').format(_eventDate!);
      }
    }
    
    return AlertDialog(
      title: Text('New Announcement', style: AppTypography.h3),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Announcement Type Selector
                DropdownButtonFormField<String>(
                  initialValue: _announcementType,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Row(
                      children: [Icon(Icons.campaign, size: 18), SizedBox(width: 8), Text('General')],
                    )),
                    DropdownMenuItem(value: 'holiday', child: Row(
                      children: [Icon(Icons.celebration, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Holiday')],
                    )),
                    DropdownMenuItem(value: 'event', child: Row(
                      children: [Icon(Icons.event, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Event')],
                    )),
                  ],
                  onChanged: (v) => setState(() {
                    _announcementType = v!;
                    if (v == 'holiday') _priority = 'high';
                  }),
                ),
                
                // Date Picker for Holiday/Event
                if (_announcementType != 'general') ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _announcementType == 'holiday' ? 'Holiday Date(s)' : 'Event Date(s)',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        dateText,
                        style: TextStyle(
                          color: _eventDate != null ? colors.onSurface : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Title',
                  controller: _titleController,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Content',
                  controller: _contentController,
                  maxLines: 4,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                
                // Only show priority for general announcements
                if (_announcementType == 'general') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('priority_$_priority'), // Force rebuild when priority changes programmatically
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ],
                
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _targetRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Users')),
                    DropdownMenuItem(value: 'student', child: Text('Students Only')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teachers Only')),
                  ],
                  onChanged: (v) => setState(() => _targetRole = v),
                ),
                if (_targetRole == 'student')
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      'This will be visible only to students assigned to you.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _announcementType == 'holiday' 
              ? Colors.orange 
              : _announcementType == 'event' 
                ? Colors.blue 
                : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_announcementType == 'holiday' ? 'Create Holiday' : _announcementType == 'event' ? 'Create Event' : 'Post'),
        ),
      ],
    );
  }
}
