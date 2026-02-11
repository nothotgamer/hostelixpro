import 'package:flutter/material.dart';
import 'package:hostelixpro/models/user.dart';
import 'package:hostelixpro/services/user_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';

class MyStudentsPage extends StatefulWidget {
  const MyStudentsPage({super.key});

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  List<User> _students = [];
  bool _isLoading = true;
  String? _error;

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
      final students = await UserService.getMyStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'My Students',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadStudents,
          tooltip: 'Refresh List',
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text('No students assigned yet.', style: AppTypography.body),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_students[index]);
                      },
                    ),
    );
  }

  Widget _buildStudentCard(User student) {
    final profile = student.studentProfile;
    final admissionNo = profile?['admission_no'] ?? 'N/A';
    final room = profile?['room'] ?? 'Unassigned';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (student.displayName ?? student.email)[0].toUpperCase(),
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.displayName ?? student.email.split('@')[0],
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(student.email, style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Room $room', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('ADM: $admissionNo', style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
