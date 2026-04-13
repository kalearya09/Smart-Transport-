import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Color _color(String type) {
    switch (type) {
      case 'arrival': return AppColors.success;
      case 'delay':   return AppColors.warning;
      case 'sos':     return AppColors.sos;
      default:        return AppColors.primary;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'arrival': return Icons.directions_bus_rounded;
      case 'delay':   return Icons.warning_amber_rounded;
      case 'sos':     return Icons.sos_rounded;
      default:        return Icons.notifications_rounded;
    }
  }

  String _time(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final np    = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (np.unread > 0)
            TextButton(
                onPressed: np.markAllRead,
                child: const Text('Mark all read')),
        ],
      ),
      body: np.list.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.25)),
            const SizedBox(height: 16),
            Text('No notifications',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: np.list.length,
        itemBuilder: (ctx, i) {
          final n = np.list[i];
          final c = _color(n.type);
          return Dismissible(
            key: Key(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.white),
            ),
            onDismissed: (_) => np.delete(n.id),
            child: GestureDetector(
              onTap: () => np.markRead(n.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: n.isRead ? theme.cardColor : c.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: n.isRead ? theme.dividerColor : c.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon(n.type), color: c, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(n.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: n.isRead
                                            ? FontWeight.w400
                                            : FontWeight.w600)),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                      color: c, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.body, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(_time(n.timestamp),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.1),
            ),
          );
        },
      ),
    );
  }
}