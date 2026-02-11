import 'package:flutter/material.dart';
import 'package:hostelixpro/services/user_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/auth_provider.dart';

class StudentProfilesPage extends StatefulWidget {
  const StudentProfilesPage({super.key});

  @override
  State<StudentProfilesPage> createState() => _StudentProfilesPageState();
}

class _StudentProfilesPageState extends State<StudentProfilesPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _students = [];
  String _searchQuery = '';
  final int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await UserService.getStudentProfiles(
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      if (mounted) {
        setState(() {
          _students = data['students'] ?? [];
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
  
  List<dynamic> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final query = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name = (s['display_name'] ?? '').toString().toLowerCase();
      final room = (s['room'] ?? '').toString().toLowerCase();
      final admNo = (s['admission_no'] ?? '').toString().toLowerCase();
      return name.contains(query) || room.contains(query) || admNo.contains(query);
    }).toList();
  }
  
  void _showStudentActivities(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentActivityModal(
        studentId: student['id'],
        studentName: student['display_name'] ?? 'Student',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).currentUser?.role ?? '';
    String title = 'Students';
    if (role == 'teacher') title = 'My Students';
    if (role == 'routine_manager') title = 'Student Routines';
    
    return AppShell(
      title: title,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadStudents,
        ),
      ],
      child: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, room, or admission no...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                // Month Selector
                PopupMenuButton<int>(
                  tooltip: 'Select Month',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 20),
                        const SizedBox(width: 8),
                        Text(DateFormat('MMM yyyy').format(DateTime(_selectedYear, _selectedMonth))),
                      ],
                    ),
                  ),
                  onSelected: (month) {
                    setState(() => _selectedMonth = month);
                    _loadStudents();
                  },
                  itemBuilder: (context) => List.generate(12, (i) {
                    final m = i + 1;
                    return PopupMenuItem(
                      value: m,
                      child: Text(DateFormat('MMMM').format(DateTime(2000, m))),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    final colors = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStudents, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: colors.outlineVariant),
            const SizedBox(height: 16),
            Text('No students found', style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    // Responsive: Cards on mobile, Table on desktop
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) => _buildStudentCard(_filteredStudents[index]),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildStudentTable(),
    );
  }
  
  Widget _buildStudentCard(Map<String, dynamic> student) {
    final colors = Theme.of(context).colorScheme;
    final activities = student['activities'] as Map<String, dynamic>? ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showStudentActivities(student),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      (student['display_name'] ?? 'S')[0].toUpperCase(),
                      style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['display_name'] ?? 'Unknown', style: AppTypography.h3),
                        if (student['admission_no'] != null)
                          Text(student['admission_no'], style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (student['room'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Room ${student['room']}', style: TextStyle(fontSize: 12, color: colors.onSecondaryContainer)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Activity badges
              Wrap(
                spacing: 8,
                children: [
                  _activityBadge(Icons.directions_walk, activities['walks'] ?? 0, AppColors.info, 'Walks'),
                  _activityBadge(Icons.exit_to_app, activities['exits'] ?? 0, AppColors.warning, 'Exits'),
                  _activityBadge(Icons.home, activities['returns'] ?? 0, AppColors.success, 'Returns'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _activityBadge(IconData icon, int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
  
  Widget _buildStudentTable() {
    final colors = Theme.of(context).colorScheme;
    
    return DataTable(
      columns: const [
        DataColumn(label: Text('Student')),
        DataColumn(label: Text('Admission No')),
        DataColumn(label: Text('Room')),
        DataColumn(label: Text('Teacher')),
        DataColumn(label: Text('Walks')),
        DataColumn(label: Text('Exits')),
        DataColumn(label: Text('Returns')),
      ],
      rows: _filteredStudents.map((student) {
        final activities = student['activities'] as Map<String, dynamic>? ?? {};
        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      (student['display_name'] ?? 'S')[0].toUpperCase(),
                      style: TextStyle(color: colors.onPrimaryContainer, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(student['display_name'] ?? 'Unknown'),
                ],
              ),
              onTap: () => _showStudentActivities(student),
            ),
            DataCell(Text(student['admission_no'] ?? '-')),
            DataCell(Text(student['room'] ?? '-')),
            DataCell(Text(student['assigned_teacher_name'] ?? '-')),
            DataCell(Text('${activities['walks'] ?? 0}')),
            DataCell(Text('${activities['exits'] ?? 0}')),
            DataCell(Text('${activities['returns'] ?? 0}')),
          ],
        );
      }).toList(),
    );
  }
}

// Student Activity Modal with Calendar
class _StudentActivityModal extends StatefulWidget {
  final int studentId;
  final String studentName;
  
  const _StudentActivityModal({required this.studentId, required this.studentName});
  
  @override
  State<_StudentActivityModal> createState() => _StudentActivityModalState();
}

class _StudentActivityModalState extends State<_StudentActivityModal> {
  bool _isLoading = true;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Map<String, dynamic> _summary = {};
  
  @override
  void initState() {
    super.initState();
    _loadActivities();
  }
  
  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await UserService.getStudentActivities(
        widget.studentId,
        year: _year,
        month: _month,
      );
      
      if (mounted) {
        setState(() {
          _summary = data['summary'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      else if (_month < 1) { _month = 12; _year--; }
    });
    _loadActivities();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: colors.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      child: Text(widget.studentName[0].toUpperCase(), style: TextStyle(color: colors.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.studentName, style: AppTypography.h3)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                  Text(DateFormat('MMMM yyyy').format(DateTime(_year, _month)), style: AppTypography.h3),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                ],
              ),
              
              const Divider(),
              
              // Calendar
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCalendar(),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCalendar() {
    final colors = Theme.of(context).colorScheme;
    final firstDay = DateTime(_year, _month, 1);
    final lastDay = DateTime(_year, _month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    
    final days = <Widget>[];
    
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    
    for (var day = 1; day <= lastDay.day; day++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_year, _month, day));
      final daySummary = _summary[dateStr] as Map<String, dynamic>?;
      final total = daySummary?['total'] ?? 0;
      final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
      
      days.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: total > 0 ? AppColors.info.withAlpha(30) : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: colors.primary, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
              if (total > 0)
                Text('$total', style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurfaceVariant)))))
              .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            padding: const EdgeInsets.all(8),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: days,
          ),
        ),
      ],
    );
  }
}
