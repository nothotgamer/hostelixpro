import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/auth_provider.dart';
import 'package:hostelixpro/widgets/notifications/notification_bell.dart';

/// Professional Navigation Sidebar using Material Design 3 patterns
class AppSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const AppSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  static const double expandedWidth = 240.0;
  static const double collapsedWidth = 68.0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final role = user?.role ?? 'student';
    final colors = Theme.of(context).colorScheme;
    final width = isCollapsed ? collapsedWidth : expandedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      child: Material(
        color: colors.surfaceContainerLow,
        child: Column(
          children: [
            // App Logo & Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isCollapsed ? 64 : 120, // Taller header for expanded state
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16, vertical: 8),
              child: isCollapsed 
                ? Center(
                    child: IconButton(
                      onPressed: onToggle,
                      icon: const Icon(Icons.menu),
                      tooltip: 'Expand',
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Large Logo
                      Expanded(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 90, // Significantly larger
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      
                      // Toggle Button (aligned to right, vertically centered)
                      IconButton(
                        onPressed: onToggle,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Collapse',
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainer,
                        ),
                      ),
                    ],
                  ),
            ),
            
            Divider(height: 1, color: colors.outlineVariant),
            
            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavTile(label: 'Dashboard', icon: Icons.dashboard, route: '/dashboard', collapsed: isCollapsed),
                    
                    if (['student', 'teacher'].contains(role))
                      _NavTile(label: 'Reports', icon: Icons.assignment, route: '/reports', collapsed: isCollapsed),
                    
                    // Students page for multiple roles
                    if (['admin', 'teacher', 'routine_manager'].contains(role))
                      _NavTile(label: 'Students', icon: Icons.school, route: '/students', collapsed: isCollapsed),
                        
                    if (['student', 'routine_manager'].contains(role))
                      _NavTile(label: 'Routines', icon: Icons.schedule, route: '/routines', collapsed: isCollapsed),
                       
                    if (role == 'student')
                      _NavTile(label: 'Fees', icon: Icons.payments, route: '/fees', collapsed: isCollapsed),
                       
                      _NavTile(label: 'Announcements', icon: Icons.campaign, route: '/announcements', collapsed: isCollapsed),
                      _NavTile(label: 'Settings', icon: Icons.settings, route: '/settings', collapsed: isCollapsed),
                    
                      if (role == 'admin') ...[
                        const SizedBox(height: 16),
                        if (!isCollapsed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.primary)),
                          ),
                        _NavTile(label: 'Activities', icon: Icons.calendar_month, route: '/admin/activities', collapsed: isCollapsed),
                        _NavTile(label: 'Audit Logs', icon: Icons.history, route: '/audit-logs', collapsed: isCollapsed),
                        _NavTile(label: 'Fee Management', icon: Icons.payments, route: '/admin/fees', collapsed: isCollapsed),
                        _NavTile(label: 'Backups', icon: Icons.backup, route: '/backups', collapsed: isCollapsed),
                        _NavTile(label: 'Users', icon: Icons.people, route: '/users', collapsed: isCollapsed),
                      ]
                  ],
                ),
              ),
            ),
            
            // Notifications (moved from header)
            if (user != null) ...[
               Container(
                margin: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16, vertical: 8),
                alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
                child: isCollapsed 
                  ? const NotificationBell()
                  : Row(
                      children: [
                        const NotificationBell(),
                        const SizedBox(width: 4),
                        Text('Notifications', style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                      ],
                    ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
            ],

            // User Profile at bottom
            if (user != null)
              Container(
                padding: EdgeInsets.all(isCollapsed ? 10 : 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: isCollapsed
                    ? CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          (user.displayName ?? user.email)[0].toUpperCase(),
                          style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.primaryContainer,
                            child: Text(
                              (user.displayName ?? user.email)[0].toUpperCase(),
                              style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.displayName ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  role.toUpperCase(),
                                  style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool collapsed;

  const _NavTile({
    required this.label,
    required this.icon,
    required this.route,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final isActive = location.startsWith(route);
    final colors = Theme.of(context).colorScheme;

    final tile = Container(
      margin: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 8, vertical: 2),
      child: Material(
        color: isActive ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(28),
          hoverColor: colors.onSurface.withValues(alpha: 0.08),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 16),
            alignment: collapsed ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: collapsed ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: isActive ? colors.onSecondaryContainer : colors.onSurfaceVariant),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: label, child: tile) : tile;
  }
}
