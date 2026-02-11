import 'package:flutter/material.dart';
import 'package:hostelixpro/services/routine_service.dart';
import 'package:hostelixpro/services/announcement_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';

class StudentActivitiesPage extends StatefulWidget {
  const StudentActivitiesPage({super.key});

  @override
  State<StudentActivitiesPage> createState() => _StudentActivitiesPageState();
}

class _StudentActivitiesPageState extends State<StudentActivitiesPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic> _activities = {};
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _holidays = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final results = await Future.wait([
        RoutineService.getCalendar(_selectedYear, _selectedMonth),
        AnnouncementService.getHolidays(_selectedYear),
      ]);
      
      final calendarData = results[0] as Map<String, dynamic>;
      final holidaysData = results[1] as List<dynamic>;
      
      if (mounted) {
        setState(() {
          _activities = calendarData['activities'] ?? {};
          _summary = calendarData['summary'] ?? {};
          _holidays = holidaysData.map((h) => h as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
  
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
  }
  
  bool _isHoliday(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _holidays.any((h) => h['event_date'] == dateStr);
  }
  
  Map<String, dynamic>? _getHoliday(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      return _holidays.firstWhere((h) => h['event_date'] == dateStr);
    } catch (_) {
      return null;
    }
  }
  
  void _showDayDetails(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayActivities = _activities[dateStr] as List<dynamic>? ?? [];
    final daySummary = _summary[dateStr] as Map<String, dynamic>?;
    final holiday = _getHoliday(date);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final colors = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(date),
                        style: AppTypography.h3,
                      ),
                      const Spacer(),
                      if (holiday != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Holiday',
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (holiday != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(holiday['title'] ?? 'Holiday', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                          if (holiday['content'] != null)
                            Text(holiday['content'], style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                
                // Summary
                if (daySummary != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryChip(Icons.directions_walk, 'Walks', daySummary['walks'] ?? 0, AppColors.info),
                        _buildSummaryChip(Icons.exit_to_app, 'Exits', daySummary['exits'] ?? 0, AppColors.warning),
                        _buildSummaryChip(Icons.home, 'Returns', daySummary['returns'] ?? 0, AppColors.success),
                      ],
                    ),
                  ),
                
                const Divider(),
                
                // Activities List
                Expanded(
                  child: dayActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: colors.outlineVariant),
                            const SizedBox(height: 8),
                            Text('No activities', style: TextStyle(color: colors.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dayActivities.length,
                        itemBuilder: (context, index) {
                          final activity = dayActivities[index] as Map<String, dynamic>;
                          return _buildActivityTile(activity);
                        },
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSummaryChip(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
  
  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final type = activity['type'] as String? ?? 'unknown';
    final studentName = activity['student_name'] as String? ?? 'Unknown';
    final status = activity['status'] as String? ?? '';
    final time = activity['request_time'] != null
      ? DateTime.fromMillisecondsSinceEpoch(activity['request_time'])
      : null;
    
    IconData icon = Icons.help;
    Color color = Colors.grey;
    
    if (type == 'walk') { icon = Icons.directions_walk; color = AppColors.info; }
    if (type == 'exit') { icon = Icons.exit_to_app; color = AppColors.warning; }
    if (type == 'return') { icon = Icons.home; color = AppColors.success; }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(studentName),
        subtitle: Text('${type.toUpperCase()} • ${time != null ? DateFormat.Hm().format(time) : ''}'),
        trailing: Text(status, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Activities',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
      child: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    final colors = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    // Get max width for desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCalendarWidth = screenWidth > 800 ? 600.0 : double.infinity;
    
    return Column(
      children: [
        // Month Navigator
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCalendarWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
                    style: AppTypography.h3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Weekday Headers
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCalendarWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.onSurfaceVariant)),
                    ),
                  ))
                  .toList(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Calendar Grid
        Expanded(
          child: SingleChildScrollView(
            child: _buildCalendarGrid(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    
    final days = <Widget>[];
    
    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    
    // Day cells
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      days.add(_buildDayCell(date));
    }
    
    // Constrain width on desktop for better appearance
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCalendarWidth = screenWidth > 800 ? 600.0 : double.infinity;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCalendarWidth),
        child: GridView.count(
          crossAxisCount: 7,
          padding: const EdgeInsets.all(8),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.0, // Square cells
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: days,
        ),
      ),
    );
  }
  
  Widget _buildDayCell(DateTime date) {
    final colors = Theme.of(context).colorScheme;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final daySummary = _summary[dateStr] as Map<String, dynamic>?;
    final isHoliday = _isHoliday(date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
    final total = daySummary?['total'] ?? 0;
    
    return InkWell(
      onTap: () => _showDayDetails(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isHoliday 
            ? AppColors.danger.withValues(alpha: 0.15)
            : isToday 
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: colors.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isHoliday ? AppColors.danger : colors.onSurface,
              ),
            ),
            if (total > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
