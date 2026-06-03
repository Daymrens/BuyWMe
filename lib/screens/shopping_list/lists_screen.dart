import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../models/shopping_item.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../theme/app_theme.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    // Calculate dashboard stats
    final totalCarts = lists.length;
    final totalItems = lists.fold<int>(0, (sum, list) => sum + list.items.length);
    final totalSpent = lists.fold<double>(
      0,
      (sum, list) => sum + list.items.fold<double>(
        0,
        (itemSum, item) => itemSum + (item.estimatedPrice * item.quantity),
      ),
    );
    final activeCarts = lists.where((list) => list.items.any((item) => !item.isDone)).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showAddCartBottomSheet(context, ref);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Cart'),
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'My Carts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          // Dashboard Summary Cards
          if (lists.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDashboardCard(
                      context,
                      'Total Carts',
                      totalCarts.toString(),
                      Icons.shopping_cart,
                      Colors.blue,
                    ).animate().fadeIn(delay: 0.ms).slideX(begin: -0.2, end: 0),
                    _buildDashboardCard(
                      context,
                      'Total Items',
                      totalItems.toString(),
                      Icons.inventory_2,
                      Colors.orange,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                    _buildDashboardCard(
                      context,
                      'Total Spent',
                      currencyFormat.format(totalSpent),
                      Icons.attach_money,
                      AppTheme.primaryGreen,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                    _buildDashboardCard(
                      context,
                      'Active Carts',
                      activeCarts.toString(),
                      Icons.local_fire_department,
                      Colors.red,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                  ],
                ),
              ),
            ),
          // Favorites Section
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final favorites = ref.watch(favoriteProvider);
                
                if (favorites.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];
                          return _buildFavoriteItem(
                            context,
                            ref,
                            lists,
                            favorite,
                            index,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (lists.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Your Carts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          lists.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset(
                            'assets/lottie/empty_cart.json',
                            repeat: true,
                            animate: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No carts yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first cart',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final list = lists[index];
                        final total = list.items.fold<double>(
                          0,
                          (sum, item) => sum + (item.estimatedPrice * item.quantity),
                        );
                        final doneCount = list.items.where((i) => i.isDone).length;
                        final progress = list.items.isEmpty ? 0.0 : doneCount / list.items.length;

                        return Dismissible(
                          key: Key(list.id),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              // Swipe left - show action menu
                              _showCartActionsSheet(context, ref, list);
                              return false;
                            } else if (direction == DismissDirection.startToEnd) {
                              // Swipe right - open cart
                              HapticFeedback.lightImpact();
                              context.push('/cart/${list.id}');
                              return false;
                            }
                            return false;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                                SizedBox(height: 4),
                                Text('Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.withValues(alpha: 0.7), Colors.blue],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.more_horiz, color: Colors.white, size: 30),
                                SizedBox(height: 4),
                                Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          child: GlassmorphicCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/cart/${list.id}');
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Hero(
                                        tag: 'cart_icon_${list.id}',
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: const Icon(
                                            Icons.shopping_bag,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              list.name,
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            if (list.storeName != null)
                                              Text(
                                                list.storeName!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.primaryGreen,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryGreen,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 6,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${list.items.length} items • $doneCount done',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        currencyFormat.format(total),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (list.budget != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Budget: ${currencyFormat.format(list.budget)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: total > list.budget!
                                                ? Colors.red.withValues(alpha: 0.2)
                                                : Colors.green.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            total > list.budget!
                                                ? 'Over budget'
                                                : 'Within budget',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: total > list.budget!
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50))
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              delay: Duration(milliseconds: index * 50),
                            ),
                        );
                      },
                      childCount: lists.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showAddCartBottomSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    String? selectedStore;
    String? selectedTemplate;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) => GlassmorphicCard(
                    borderRadius: 30,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New Cart',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  autofocus: false,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Cart Name',
                    hintText: 'e.g., Weekly Shopping',
                    prefixIcon: const Icon(Icons.shopping_cart),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Budget (Optional)',
                    hintText: 'Enter your budget',
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText: '₱ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Store (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStoreChip(
                      context,
                      (fn) => setState(() => selectedStore = null),
                      selectedStore,
                      null,
                      'No Store',
                      Icons.close,
                      Colors.grey,
                    ),
                    _buildStoreChip(
                      context,
                      (fn) => setState(() => selectedStore = 'sm'),
                      selectedStore,
                      'sm',
                      'SM',
                      Icons.shopping_bag,
                      Colors.red,
                    ),
                    _buildStoreChip(
                      context,
                      (fn) => setState(() => selectedStore = 'puregold'),
                      selectedStore,
                      'puregold',
                      'Puregold',
                      Icons.store,
                      Colors.orange,
                    ),
                    _buildStoreChip(
                      context,
                      (fn) => setState(() => selectedStore = 'landers'),
                      selectedStore,
                      'landers',
                      'Landers',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                    _buildStoreChip(
                      context,
                      (fn) => setState(() => selectedStore = 'robinsons'),
                      selectedStore,
                      'robinsons',
                      'Robinsons',
                      Icons.local_grocery_store,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Template',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _buildTemplateCard(
                  context,
                  (fn) => setState(() => selectedTemplate = null),
                  selectedTemplate,
                  null,
                  '✨ Empty Cart',
                  'Start from scratch',
                  '0 items',
                  Colors.grey,
                ),
                const SizedBox(height: 8),
                _buildTemplateCard(
                  context,
                  (fn) => setState(() => selectedTemplate = 'Weekly Groceries'),
                  selectedTemplate,
                  'Weekly Groceries',
                  '🛒 Weekly Groceries',
                  'Essential items for the week',
                  '5 items • ~₱850',
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildTemplateCard(
                  context,
                  (fn) => setState(() => selectedTemplate = 'Party Supplies'),
                  selectedTemplate,
                  'Party Supplies',
                  '🎉 Party Supplies',
                  'Everything for your celebration',
                  '4 items • ~₱690',
                  Colors.purple,
                ),
                const SizedBox(height: 8),
                _buildTemplateCard(
                  context,
                  (fn) => setState(() => selectedTemplate = 'Breakfast Essentials'),
                  selectedTemplate,
                  'Breakfast Essentials',
                  '☕ Breakfast Essentials',
                  'Start your day right',
                  '4 items • ~₱550',
                  Colors.orange,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              HapticFeedback.mediumImpact();
                              final budget = budgetController.text.isEmpty
                                  ? null
                                  : double.tryParse(budgetController.text);

                              final storeNames = {
                                'sm': 'SM Supermarket',
                                'puregold': 'Puregold',
                                'landers': 'Landers',
                                'robinsons': 'Robinsons',
                              };

                              if (selectedTemplate != null && selectedTemplate!.isNotEmpty) {
                                ref.read(shoppingListProvider.notifier).addListFromTemplate(
                                      nameController.text,
                                      selectedTemplate!,
                                      budget: budget,
                                      storeId: selectedStore,
                                      storeName: selectedStore != null ? storeNames[selectedStore] : null,
                                    );
                              } else {
                                ref.read(shoppingListProvider.notifier).addList(
                                      nameController.text,
                                      budget: budget,
                                      storeId: selectedStore,
                                      storeName: selectedStore != null ? storeNames[selectedStore] : null,
                                    );
                              }
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${nameController.text} created!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Create Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    ),
    );
      },
    );
  }

  void _showCartActionsSheet(BuildContext context, WidgetRef ref, dynamic cart) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: GlassmorphicCard(
                borderRadius: 30,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cart Actions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            _buildActionTile(
              context,
              icon: Icons.edit,
              title: 'Rename Cart',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, cart);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.attach_money,
              title: 'Edit Budget',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _showEditBudgetDialog(context, ref, cart);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.check_circle,
              title: 'Check All',
              color: AppTheme.primaryGreen,
              onTap: () {
                HapticFeedback.mediumImpact();
                for (var item in cart.items) {
                  if (!item.isDone) {
                    ref.read(shoppingListProvider.notifier).toggleItem(cart.id, item.id);
                  }
                }
                Navigator.pop(context);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.cancel,
              title: 'Uncheck All',
              color: Colors.orange,
              onTap: () {
                HapticFeedback.mediumImpact();
                for (var item in cart.items) {
                  if (item.isDone) {
                    ref.read(shoppingListProvider.notifier).toggleItem(cart.id, item.id);
                  }
                }
                Navigator.pop(context);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.delete_sweep,
              title: 'Delete Checked',
              color: Colors.deepOrange,
              onTap: () {
                HapticFeedback.mediumImpact();
                final checkedItems = cart.items.where((i) => i.isDone).toList();
                for (var item in checkedItems) {
                  ref.read(shoppingListProvider.notifier).deleteItem(cart.id, item.id);
                }
                Navigator.pop(context);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.share,
              title: 'Share List',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _shareCartAsText(context, cart);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.save,
              title: 'Save as Template',
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                _saveAsTemplate(context, ref, cart);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.file_download,
              title: 'Export CSV',
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                _exportAsCsv(context, cart);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.check_circle_outline,
              title: 'Complete Trip',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _completeTripDialog(context, ref, cart);
              },
            ),
            const Divider(height: 32),
            _buildActionTile(
              context,
              icon: Icons.delete,
              title: 'Delete Cart',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, ref, cart);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    ),
    ),
    );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    final controller = TextEditingController(text: cart.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Cart'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Cart name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                cart.name = controller.text;
                cart.save();
                ref.read(shoppingListProvider.notifier).refreshLists();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    final controller = TextEditingController(
      text: cart.budget?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Budget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Budget amount',
            prefixText: '₱ ',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final budget = controller.text.isEmpty ? null : double.tryParse(controller.text);
              cart.budget = budget;
              cart.save();
              ref.read(shoppingListProvider.notifier).refreshLists();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cart'),
        content: Text('Are you sure you want to delete "${cart.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(shoppingListProvider.notifier).deleteList(cart.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: GlassmorphicCard(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


  Widget _buildTemplateCard(
    BuildContext context,
    Function(void Function()) setStateCallback,
    String? selectedTemplate,
    String? templateValue,
    String title,
    String description,
    String details,
    Color accentColor,
  ) {
    final isSelected = selectedTemplate == templateValue;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setStateCallback(() {
          // This will be handled by the parent
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  title.split(' ')[0],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.substring(title.indexOf(' ') + 1),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? accentColor : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildStoreChip(
    BuildContext context,
    Function(void Function()) setStateCallback,
    String? selectedStore,
    String? storeValue,
    String storeName,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedStore == storeValue;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setStateCallback(() {
          // This will be handled by the parent
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              storeName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : null,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 18,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Share cart as plain text via clipboard
  void _shareCartAsText(BuildContext context, dynamic cart) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.estimatedPrice * item.quantity));

    final buffer = StringBuffer();
    buffer.writeln('🛒 ${cart.name}');
    if (cart.storeName != null) buffer.writeln('📍 ${cart.storeName}');
    buffer.writeln('');

    for (final item in cart.items) {
      final status = item.isDone ? '✅' : '⬜';
      buffer.writeln(
          '$status ${item.name}  ×${item.quantity} ${item.unit}  ${currencyFormat.format(item.estimatedPrice * item.quantity)}');
    }

    buffer.writeln('');
    buffer.writeln('Total: ${currencyFormat.format(total)}');
    if (cart.budget != null) {
      buffer.writeln('Budget: ${currencyFormat.format(cart.budget)}');
    }

    final text = buffer.toString();
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cart copied to clipboard — paste to share!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Export cart as CSV text via clipboard
  void _exportAsCsv(BuildContext context, dynamic cart) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Quantity,Unit,Unit Price,Total,Done');

    for (final item in cart.items) {
      final name = '"${item.name.replaceAll('"', '""')}"';
      final done = item.isDone ? 'Yes' : 'No';
      buffer.writeln(
          '$name,${item.quantity},${item.unit},${item.estimatedPrice},${item.estimatedPrice * item.quantity},$done');
    }

    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.estimatedPrice * item.quantity));
    buffer.writeln('"TOTAL",,,,$total,');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV copied to clipboard!'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Save current cart items as a new template cart
  void _saveAsTemplate(BuildContext context, WidgetRef ref, dynamic cart) {
    final nameController = TextEditingController(text: '${cart.name} (Template)');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Template name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);

              // Create a new cart with the same items (all unchecked)
              final notifier = ref.read(shoppingListProvider.notifier);
              notifier.addList(name, budget: cart.budget, storeId: cart.storeId, storeName: cart.storeName);
              final newLists = ref.read(shoppingListProvider);
              // The new list was just added at the end
              if (newLists.isNotEmpty) {
                final newCart = newLists.last;
                for (final item in cart.items as List) {
                  final newItem = ShoppingItem(
                    id: const Uuid().v4(),
                    productId: item.productId,
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    estimatedPrice: item.estimatedPrice,
                  );
                  notifier.addItem(newCart.id, newItem);
                }
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$name" saved as a new cart!'),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Mark all items as done and show trip summary
  void _completeTripDialog(BuildContext context, WidgetRef ref, dynamic cart) {
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.estimatedPrice * item.quantity));
    final doneCount = (cart.items as List).where((i) => i.isDone).length;
    final totalCount = (cart.items as List).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Complete Trip'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark remaining items as done and complete this trip?'),
            const SizedBox(height: 12),
            Text('Progress: $doneCount / $totalCount items done'),
            Text('Total spent: ${currencyFormat.format(total)}'),
            if (cart.budget != null)
              Text(
                total > cart.budget
                    ? 'Over budget by ${currencyFormat.format(total - cart.budget)}'
                    : 'Saved ${currencyFormat.format(cart.budget - total)} from budget',
                style: TextStyle(
                  color: total > cart.budget ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Mark all items as done
              for (final item in cart.items as List) {
                if (!item.isDone) {
                  ref.read(shoppingListProvider.notifier).toggleItem(cart.id, item.id);
                }
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trip completed! Total: ${currencyFormat.format(total)}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> lists,
    dynamic favorite,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassmorphicCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (lists.isNotEmpty) {
              final currentList = lists.first;
              final newItem = ShoppingItem(
                id: const Uuid().v4(),
                productId: const Uuid().v4(),
                name: favorite.itemName,
                quantity: 1,
                unit: 'pcs',
                estimatedPrice: favorite.price ?? 0.0,
              );
              ref.read(shoppingListProvider.notifier).addItem(currentList.id, newItem);
              ref.read(favoriteProvider.notifier).incrementAddedCount(favorite.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${favorite.itemName} added to ${currentList.name}!'),
                  backgroundColor: AppTheme.primaryGreen,
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showFavoriteDetailsSheet(context, ref, favorite);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  favorite.itemName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '×${favorite.addedCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn()
        .slideX(begin: 0.1),
    );
  }

  void _showFavoriteDetailsSheet(BuildContext context, WidgetRef ref, dynamic favorite) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: GlassmorphicCard(
                borderRadius: 30,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        favorite.itemName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(
                        context,
                        'Times Added',
                        favorite.addedCount.toString(),
                        Icons.shopping_cart,
                      ),
                      const SizedBox(height: 12),
                      if (favorite.price != null && favorite.price! > 0)
                        _buildInfoRow(
                          context,
                          'Price',
                          '₱${favorite.price!.toStringAsFixed(2)}',
                          Icons.attach_money,
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(favoriteProvider.notifier).removeFavorite(favorite.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${favorite.itemName} removed from favorites'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove from Favorites'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

