import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../theme/app_theme.dart';
import 'my_stores_screen.dart';
import 'shopping_history_screen.dart';
import 'manage_categories_screen.dart';
import 'quick_scan_screen.dart';
import '../stats/expense_stats_screen.dart';

final nicknameProvider = StateProvider<String>((ref) => 'Guest User');

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('user_nickname') ?? 'Guest User';
    ref.read(nicknameProvider.notifier).state = nickname;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final nickname = ref.watch(nicknameProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.3),
                      AppTheme.gradientEnd.withOpacity(0.2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 45,
                          color: Colors.white,
                        ),
                      ).animate().scale(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                      Text(
                        nickname,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Free Plan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Card
                GlassmorphicCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          '0',
                          'Carts',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          '0',
                          'Items',
                          Icons.inventory_2,
                          Colors.orange,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          '₱0',
                          'Saved',
                          Icons.savings,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                
                // Preferences Section
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: themeMode == ThemeMode.system ? Icons.brightness_auto : (isDark ? Icons.light_mode : Icons.dark_mode),
                        title: 'Theme',
                        subtitle: _getThemeLabel(themeMode),
                        color: isDark ? Colors.amber : Colors.indigo,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showThemeSelector(context, ref);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage your alerts',
                        color: Colors.purple,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showComingSoon(context);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: 'English',
                        color: Colors.blue,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showComingSoon(context);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
                const SizedBox(height: 24),
                
                // Shopping Section
                Text(
                  'Shopping',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.store,
                        title: 'My Stores',
                        subtitle: 'Manage favorite stores',
                        color: Colors.red,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyStoresScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.qr_code_scanner,
                        title: 'Scan Barcode',
                        subtitle: 'Quick scan products',
                        color: Colors.teal,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final barcode = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QuickScanScreen()),
                          );
                          if (barcode != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Scanned: $barcode'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.history,
                        title: 'Shopping History',
                        subtitle: 'View past purchases',
                        color: Colors.orange,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ShoppingHistoryScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.category,
                        title: 'Categories',
                        subtitle: 'Organize your items',
                        color: Colors.pink,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.analytics_outlined,
                        title: 'Expense Analytics',
                        subtitle: 'View spending statistics',
                        color: Colors.teal,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ExpenseStatsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
                const SizedBox(height: 24),
                
                // More Section
                Text(
                  'More',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get assistance',
                        color: Colors.cyan,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showComingSoon(context);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Your data is safe',
                        color: Colors.deepPurple,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showComingSoon(context);
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        context,
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        color: Colors.blueGrey,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0, delay: 400.ms),
                const SizedBox(height: 24),
                
                // Sign Out Button
                GlassmorphicCard(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showSignOutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Preference';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              ThemeMode.system,
              'System Preference',
              'Follow device settings',
              Icons.brightness_auto,
              currentTheme == ThemeMode.system,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.light,
              'Light Mode',
              'Always use light theme',
              Icons.light_mode,
              currentTheme == ThemeMode.light,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.dark,
              'Dark Mode',
              'Always use dark theme',
              Icons.dark_mode,
              currentTheme == ThemeMode.dark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
    bool selected,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primaryGreen : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppTheme.primaryGreen : null,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('GroceryMate'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0'),
            const SizedBox(height: 8),
            Text(
              'Your smart grocery companion for better shopping.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('© 2026 GroceryMate'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
