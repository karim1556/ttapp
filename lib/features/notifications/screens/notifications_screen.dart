import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_center_provider.dart';
import '../../../widgets/empty_state_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationCenterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationCenterProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
          IconButton(
            onPressed: () => ref.read(notificationCenterProvider.notifier).clearAll(),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationCenterProvider.notifier).refresh(),
        child: state.items.isEmpty
          ? ListView(
                children: [
                  SizedBox(height: 80),
                  EmptyStateWidget(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle: 'Substitution approvals and reminders will appear here.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final received = item.receivedDateTime;
                  final when = received == null
                      ? ''
                      : DateFormat('d MMM, hh:mm a').format(received.toLocal());

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ref.read(notificationCenterProvider.notifier).markAsRead(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? AppColors.textSecondary.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.isRead
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_active_rounded,
                              color: item.isRead ? AppColors.textSecondary : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (when.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    when,
                                    style: const TextStyle(
                                      color: AppColors.textDisabled,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
