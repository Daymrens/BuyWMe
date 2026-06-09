import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/stats_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_card.dart';

class ExpenseStatsScreen extends ConsumerStatefulWidget {
  const ExpenseStatsScreen({super.key});

  @override
  ConsumerState<ExpenseStatsScreen> createState() => _ExpenseStatsScreenState();
}

class _ExpenseStatsScreenState extends ConsumerState<ExpenseStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _touchedPieIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasData = stats.monthlyTrend.isNotEmpty;
    final monthlyValues = stats.monthlyTrend.where((m) => m.total > 0).map((m) => m.total).toList();
    final avgMonthly = monthlyValues.isEmpty ? 0.0 : monthlyValues.reduce((a, b) => a + b) / monthlyValues.length;
    final bestMonth = monthlyValues.isEmpty ? null : monthlyValues.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Expense Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This Month', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('₱${stats.totalMonthly.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last 12 Months', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('₱${stats.totalYearly.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      ),
                    ],
                  ),
                  if (hasData) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.trending_up, size: 14, color: AppTheme.primaryGreen),
                                    const SizedBox(width: 4),
                                    Text('Avg/Month', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('₱${avgMonthly.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlassmorphicCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text('Best Month', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('₱${(bestMonth ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.primaryGreen,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Trend'),
                        Tab(text: 'Categories'),
                        Tab(text: 'Stores'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyTrendTab(context, stats),
                _buildCategoriesTab(context, stats),
                _buildStoresTab(context, stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendTab(BuildContext context, ExpenseStats stats) {
    if (stats.monthlyTrend.isEmpty || stats.monthlyTrend.every((m) => m.total == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No trend data yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Add shopping lists to see spending trends', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    final maxY = stats.monthlyTrend.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Monthly Spending Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
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
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= stats.monthlyTrend.length) return const SizedBox.shrink();
                                final month = stats.monthlyTrend[index].month;
                                final parts = month.split(' ');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(parts[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text('₱${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ),
                              reservedSize: 36,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (stats.monthlyTrend.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY * 1.15,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              stats.monthlyTrend.length,
                              (index) => FlSpot(index.toDouble(), stats.monthlyTrend[index].total),
                            ),
                            isCurved: true,
                            barWidth: 3,
                            color: AppTheme.primaryGreen,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.primaryGreen,
                                strokeWidth: 2,
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
                            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              final label = index >= 0 && index < stats.monthlyTrend.length
                                  ? stats.monthlyTrend[index].month
                                  : '';
                              return LineTooltipItem(
                                '$label\n₱${spot.y.toStringAsFixed(2)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, ExpenseStats stats) {
    if (stats.categoryBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No category data', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Categories appear when products are added', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    const colors = [
      Color(0xFF00C853),
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF14B8A6),
      Color(0xFF8B5CF6),
      Color(0xFFF97316),
    ];

    final total = stats.categoryBreakdown.map((e) => e.total).reduce((a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Spending by Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = null;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(
                        stats.categoryBreakdown.length,
                        (index) {
                          final category = stats.categoryBreakdown[index];
                          final percentage = (category.total / total) * 100;
                          final isTouched = _touchedPieIndex == index;
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: category.total,
                            title: isTouched ? '₱${category.total.toStringAsFixed(0)}' : '${percentage.toStringAsFixed(0)}%',
                            radius: isTouched ? 90 : 75,
                            titleStyle: TextStyle(
                              fontSize: isTouched ? 14 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: List.generate(stats.categoryBreakdown.length, (index) {
                      final category = stats.categoryBreakdown[index];
                      final percentage = (category.total / total) * 100;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(category.category, style: const TextStyle(fontSize: 14))),
                            Text('₱${category.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text('${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildStoresTab(BuildContext context, ExpenseStats stats) {
    final topStores = stats.storeBreakdown.take(5).toList();

    if (topStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No store data', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Store data appears when carts are assigned to stores', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    final maxY = topStores.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Top 5 Stores by Spending',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
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
                                if (index < 0 || index >= topStores.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    topStores[index].store.length > 6
                                        ? '${topStores[index].store.substring(0, 6)}...'
                                        : topStores[index].store,
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text('₱${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ),
                              reservedSize: 36,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: maxY * 1.15,
                        barGroups: List.generate(topStores.length, (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: topStores[index].total,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.85 - (index * 0.12)),
                              width: 28,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        )),
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final store = topStores[group.x.toInt()];
                              return BarTooltipItem(
                                '${store.store}\n₱${rod.toY.toStringAsFixed(2)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: Column(
                    children: List.generate(topStores.length, (index) {
                      final store = topStores[index];
                      final pct = (store.total / maxY) * 100;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text('${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 14),
                              )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(store.store, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryGreen.withValues(alpha: 0.85 - (index * 0.12)),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('₱${store.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }
}
