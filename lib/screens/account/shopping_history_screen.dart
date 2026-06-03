import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../theme/app_theme.dart';

class ShoppingHistoryScreen extends ConsumerWidget {
  const ShoppingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListProvider);
    final completedLists = lists.where((list) => 
      list.items.isNotEmpty && list.items.every((item) => item.isDone)
    ).toList();
    
    completedLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1F33)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EAF6)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Shopping History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              ),
            ),
            if (completedLists.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No completed trips yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete a shopping cart to see history',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassmorphicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            completedLists.length.toString(),
                            'Trips',
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                          Container(width: 1, height: 50, color: Colors.grey.withValues(alpha: 0.2)),
                          _buildStatItem(
                            context,
                            completedLists.fold<int>(0, (sum, list) => sum + list.items.length).toString(),
                            'Items',
                            Icons.inventory_2,
                            Colors.orange,
                          ),
                          Container(width: 1, height: 50, color: Colors.grey.withValues(alpha: 0.2)),
                          _buildStatItem(
                            context,
                            currencyFormat.format(
                              completedLists.fold<double>(
                                0,
                                (sum, list) => sum + list.items.fold<double>(
                                  0,
                                  (itemSum, item) => itemSum + (item.estimatedPrice * item.quantity),
                                ),
                              ),
                            ),
                            'Total',
                            Icons.attach_money,
                            AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final list = completedLists[index];
                      final total = list.items.fold<double>(
                        0,
                        (sum, item) => sum + (item.estimatedPrice * item.quantity),
                      );
                      final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

                      return GlassmorphicCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            list.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(list.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (list.storeName != null) ...[
                                    const Icon(Icons.store, size: 14, color: AppTheme.primaryGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      list.storeName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Text(
                                    '${list.items.length} items',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            currencyFormat.format(total),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                          ),
                          children: [
                            const Divider(height: 1),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.items.length,
                              itemBuilder: (context, itemIndex) {
                                final item = list.items[itemIndex];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text('${item.quantity} ${item.unit}'),
                                  trailing: Text(
                                    currencyFormat.format(item.estimatedPrice * item.quantity),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 50))
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            delay: Duration(milliseconds: index * 50),
                          );
                    },
                    childCount: completedLists.length,
                  ),
                ),
              ),
            ],
          ],
        ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
}
