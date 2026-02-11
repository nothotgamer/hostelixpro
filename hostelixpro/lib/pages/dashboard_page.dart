// Dashboard page - Role-specific landing page
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/auth_provider.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/pages/teacher/teacher_dashboard_widget.dart';
import 'package:hostelixpro/pages/admin/admin_dashboard_widget.dart';
import 'package:hostelixpro/pages/manager/routine_manager_dashboard_widget.dart';
import 'package:hostelixpro/pages/student/student_dashboard_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    
    return AppShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: AppTypography.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back, ${user?.displayName ?? user?.email ?? 'User'}', 
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              // Logout provided in Header now, but can keep here if needed or remove
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: () {
              if (user?.role == 'admin') return const AdminDashboardWidget();
              if (user?.role == 'teacher') return const TeacherDashboardWidget();
              if (user?.role == 'routine_manager') return const RoutineManagerDashboardWidget();
              if (user?.role == 'student') return StudentDashboardWidget(userName: user?.displayName ?? 'Student');
              return const SizedBox();
            }(),
          ),
        ],
      ),
    );
  }
}
