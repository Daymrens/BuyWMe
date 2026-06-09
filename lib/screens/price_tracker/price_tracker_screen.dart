import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/price_tracker_provider.dart';
import '../../models/price_entry.dart';
import '../../models/shopping_list.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../theme/app_theme.dart';

class PriceTrackerScreen extends ConsumerWidget {
  const PriceTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(priceTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTrendChart(context, entries, isDark).animate().fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                _buildRecentEntries(context, entries, isDark).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, delay: 100.ms),
                const SizedBox(height: 16),
                _buildSavingsTips(context).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<PriceEntry> entries, bool isDark) {
    if (entries.isEmpty) {
      return GlassmorphicCard(
        child: Column(
          children: [
            _buildCardHeader(context, Icons.trending_up, 'Price Trends', 'Track your spending'),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.insights_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No price data yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Start adding items to see price trends', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, Icons.trending_up, 'Price Trends', 'Last ${entries.length > 10 ? 10 : entries.length} entries'),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: entries.length < 3
                ? Center(
                    child: Text(
                      'Need at least 3 entries to show a chart',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${entries[index].date.month}/${entries[index].date.day}',
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              );
                            },
                            reservedSize: 24,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              '₱${value.toInt()}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                            reservedSize: 36,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (entries.length - 1).toDouble(),
                      minY: 0,
                      maxY: (entries.map((e) => e.price).reduce((a, b) => a > b ? a : b)) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            entries.length,
                            (index) => FlSpot(index.toDouble(), entries[index].price),
                          ),
                          isCurved: true,
                          barWidth: 2.5,
                          color: AppTheme.primaryGreen,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 3,
                              color: AppTheme.primaryGreen,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
                            '₱${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecentEntries(BuildContext context, List<PriceEntry> entries, bool isDark) {
    final productNames = _loadProductNames();
    final recent = entries.length > 5 ? entries.sublist(entries.length - 5) : entries;

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, Icons.receipt_long, 'Recent Price History', 'Last ${recent.length} entries'),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No entries yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ...recent.reversed.map((entry) {
              final productName = productNames[entry.productId] ?? _formatProductId(entry.productId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_basket, color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${entry.date.month}/${entry.date.day}/${entry.date.year}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₱${entry.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSavingsTips(BuildContext context) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, Icons.savings_outlined, 'Savings Tips', 'Smart shopping insights'),
          const SizedBox(height: 16),
          _buildTipCard(context, Icons.compare_arrows, 'Compare prices', 'Check multiple stores for the best deals on your regular items'),
          const SizedBox(height: 8),
          _buildTipCard(context, Icons.calendar_month, 'Plan ahead', 'Create a weekly shopping list to avoid impulse buys and save more'),
          const SizedBox(height: 8),
          _buildTipCard(context, Icons.track_changes, 'Track prices', 'Monitor price changes over time to buy when items are cheapest'),
          const SizedBox(height: 8),
          _buildTipCard(context, Icons.shopping_bag, 'Buy in bulk', 'Stock up on non-perishables when prices drop'),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _loadProductNames() {
    final names = <String, String>{};
    try {
      final listBox = Hive.box<ShoppingList>('shopping_lists');
      for (final list in listBox.values) {
        for (final item in list.items) {
          if (item.productId.isNotEmpty && !names.containsKey(item.productId)) {
            names[item.productId] = item.name;
          }
        }
      }
    } catch (_) {}
    return names;
  }

  String _formatProductId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }
}
