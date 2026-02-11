import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostelixpro/services/notification_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:intl/intl.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }
  
  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsSheet(
        onClose: () {
          Navigator.pop(context);
          _loadUnreadCount();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return IconButton(
      onPressed: _showNotificationsSheet,
      icon: Badge(
        isLabelVisible: _unreadCount > 0,
        label: Text(
          _unreadCount > 9 ? '9+' : '$_unreadCount',
          style: const TextStyle(fontSize: 10),
        ),
        child: Icon(Icons.notifications_outlined, color: colors.onSurface),
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final VoidCallback onClose;
  
  const _NotificationsSheet({required this.onClose});

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceContainerHigh : colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: colors.outlineVariant),
            
            // List
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: colors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No notifications', style: TextStyle(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          onTap: () async {
                            await NotificationService.markAsRead(notification.id);
                            if (notification.actionUrl != null && context.mounted) {
                              widget.onClose();
                              context.push(notification.actionUrl!);
                            } else {
                              _loadNotifications();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(notification.createdAt);
    final timeAgo = _formatTimeAgo(date);
    
    Color typeColor = colors.primary;
    IconData typeIcon = Icons.info_outline;
    
    switch (notification.type) {
      case 'success':
        typeColor = AppColors.success;
        typeIcon = Icons.check_circle_outline;
        break;
      case 'warning':
        typeColor = AppColors.warning;
        typeIcon = Icons.warning_amber_outlined;
        break;
      case 'error':
        typeColor = AppColors.danger;
        typeIcon = Icons.error_outline;
        break;
    }
    
    return Card(
      color: notification.isRead 
        ? colors.surfaceContainerLow 
        : colors.primaryContainer.withValues(alpha: 0.3),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
        trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      ),
    );
  }
  
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return DateFormat('MMM d').format(date);
  }
}
