import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hostelixpro/providers/auth_provider.dart';
import 'package:hostelixpro/providers/sidebar_provider.dart';
import 'package:hostelixpro/providers/theme_provider.dart';
import 'package:hostelixpro/pages/auth/splash_page.dart';
import 'package:hostelixpro/pages/auth/login_page.dart';
import 'package:hostelixpro/pages/auth/signup_page.dart';
import 'package:hostelixpro/pages/auth/forgot_password_page.dart';
import 'package:hostelixpro/pages/auth/reset_password_page.dart';
import 'package:hostelixpro/pages/dashboard_page.dart';
import 'package:hostelixpro/pages/student/routine_page.dart';
import 'package:hostelixpro/pages/student/fee_page.dart';
import 'package:hostelixpro/pages/common/announcements_page.dart';
import 'package:hostelixpro/pages/admin/audit_logs_page.dart';
import 'package:hostelixpro/pages/admin/backup_restore_page.dart';
import 'package:hostelixpro/pages/teacher/my_students_page.dart'; // Added
import 'package:hostelixpro/pages/common/settings_page.dart';
import 'package:hostelixpro/pages/admin/users_management_page.dart'; // Added
import 'package:hostelixpro/pages/admin/fee_management_page.dart'; // Added
import 'package:hostelixpro/pages/admin/student_activities_page.dart'; // Added
import 'package:hostelixpro/pages/common/student_profiles_page.dart'; // Added
import 'package:hostelixpro/pages/common/reports_page.dart';

void main() {
  runApp(const HostelixProApp());
}

class HostelixProApp extends StatelessWidget {
  const HostelixProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Hostelix Pro',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

/// GoRouter configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResetPasswordPage(
          txId: extra?['txId'] ?? '',
          email: extra?['email'] ?? '',
        );
      },
    ),
    // Main App Routes with Fade Transition
    GoRoute(
      path: '/routines',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RoutinePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/fees',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FeePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DashboardPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/announcements',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AnnouncementsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/audit-logs',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuditLogsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/backups',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BackupRestorePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/users',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const UsersManagementPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/admin/fees',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FeeManagementPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/admin/activities',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StudentActivitiesPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/students',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StudentProfilesPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/reports',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ReportsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/my-students',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MyStudentsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
  ],
);
