import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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
          // Summary Cards
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
                              const Text(
                                'This Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₱${stats.totalMonthly.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassmorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last 12 Months',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₱${stats.totalYearly.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2),
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
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Monthly Trend Tab
                _buildMonthlyTrendTab(context, stats),
                // Categories Tab
                _buildCategoriesTab(context, stats),
                // Stores Tab
                _buildStoresTab(context, stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendTab(BuildContext context, ExpenseStats stats) {
    if (stats.monthlyTrend.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final maxY = stats.monthlyTrend.isEmpty
        ? 1.0
        : stats.monthlyTrend.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Spending Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= stats.monthlyTrend.length) {
                                return const SizedBox.shrink();
                              }
                              final month = stats.monthlyTrend[index].month;
                              final parts = month.split(' ');
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  parts[0],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '₱${(value / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (stats.monthlyTrend.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            stats.monthlyTrend.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              stats.monthlyTrend[index].total,
                            ),
                          ),
                          isCurved: true,
                          barWidth: 3,
                          color: AppTheme.primaryGreen,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.primaryGreen,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
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
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '₱${spot.y.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, ExpenseStats stats) {
    if (stats.categoryBreakdown.isEmpty) {
      return Center(
        child: Text(
          'No category data available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final colors = [
      AppTheme.primaryGreen,
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(
                        stats.categoryBreakdown.length,
                        (index) {
                          final category = stats.categoryBreakdown[index];
                          final total = stats.categoryBreakdown
                              .map((e) => e.total)
                              .reduce((a, b) => a + b);
                          final percentage = (category.total / total) * 100;
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: category.total,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Legend
                Column(
                  children: List.generate(
                    stats.categoryBreakdown.length,
                    (index) {
                      final category = stats.categoryBreakdown[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(category.category),
                            ),
                            Text(
                              '₱${category.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresTab(BuildContext context, ExpenseStats stats) {
    final topStores = stats.storeBreakdown.take(5).toList();
    
    if (topStores.isEmpty) {
      return Center(
        child: Text(
          'No store data available',
          style: Theme.of(context).textTheme.bodyLarge,
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
                Text(
                  'Top 5 Stores by Spending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= topStores.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  topStores[index].store.length > 8
                                      ? '${topStores[index].store.substring(0, 8)}...'
                                      : topStores[index].store,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '₱${(value / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY * 1.1,
                      barGroups: List.generate(
                        topStores.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: topStores[index].total,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.8 - (index * 0.1)),
                              width: 30,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '₱${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Store List
                Column(
                  children: List.generate(
                    topStores.length,
                    (index) {
                      final store = topStores[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.store,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${store.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
