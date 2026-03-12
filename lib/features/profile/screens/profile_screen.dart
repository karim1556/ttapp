import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isFaculty = ref.watch(isFacultyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar & name
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (user?.email.isNotEmpty == true)
                          ? user!.email[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.email.split('@').first ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _roleColor(user).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.userTypeLabel ?? '',
                    style: TextStyle(
                      color: _roleColor(user),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: user?.userTypeLabel ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.fingerprint_outlined,
                    label: 'User ID',
                    value: user?.uid.toString() ?? '—',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Faculty-specific options
          if (isFaculty) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune_outlined,
                        color: AppColors.secondary),
                    title: const Text('My Scheduling Constraints'),
                    subtitle: const Text(
                        'Set max lectures, unavailable & preferred slots'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.facultyConstraints),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Admin-specific options
          if (isAdmin) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined,
                        color: AppColors.warning),
                    title: const Text('Admin Panel'),
                    subtitle: const Text(
                        'Manage teachers, subjects & timetable'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.adminPanel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // App info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded,
                      color: AppColors.textSecondary),
                  title: const Text('App Version'),
                  trailing: Text(
                    '1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Server URL (dev setting)
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
              title: const Text('Server URL'),
              subtitle: Text(
                ref.watch(serverUrlProvider),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editServerUrl(context, ref),
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_outlined, color: AppColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _roleColor(UserModel? user) {
    switch (user?.userType) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.secondary;
      case 3:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _editServerUrl(BuildContext context, WidgetRef ref) async {
    final current = ref.read(serverUrlProvider);
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://192.168.x.y:3000/api',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(serverUrlProvider.notifier).updateUrl(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server URL updated to $result')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
