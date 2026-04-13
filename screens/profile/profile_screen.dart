import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth  = context.watch<AuthProvider>();
    final tp    = context.watch<ThemeProvider>();
    final user  = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user != null && user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.name ?? 'User',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(user?.phone ?? '',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 20),

            // Settings
            _section(theme, 'Preferences', [
              _tile(
                theme,
                icon: tp.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: 'Dark Mode',
                trailing: Switch(
                  value: tp.isDark,
                  activeColor: AppColors.primary,
                  onChanged: (_) => tp.toggle(),
                ),
              ),
              _tile(theme,
                  icon: Icons.favorite_rounded,
                  title: 'Favourite Routes',
                  subtitle: '${user?.favoriteRoutes.length ?? 0} saved',
                  onTap: () {}),
              _tile(theme,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => Get.toNamed(AppRoutes.notifications)),
            ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            _section(theme, 'About', [
              _tile(theme,
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0'),
              _tile(theme,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {}),
              _tile(theme,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {}),
            ]).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  Get.offAllNamed(AppRoutes.login);
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData t, String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: t.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.colorScheme.onSurface.withOpacity(0.5))),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _tile(ThemeData t, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: t.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: t.textTheme.bodyMedium) : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
              color: t.colorScheme.onSurface.withOpacity(0.4))
              : null),
      onTap: onTap,
    );
  }
}