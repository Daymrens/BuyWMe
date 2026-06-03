import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/shopping_list.dart';
import '../models/product.dart';

class MonthlyData {
  final String month;
  final double total;
  
  MonthlyData({required this.month, required this.total});
}

class CategoryData {
  final String category;
  final double total;
  
  CategoryData({required this.category, required this.total});
}

class StoreData {
  final String store;
  final double total;
  
  StoreData({required this.store, required this.total});
}

class ExpenseStats {
  final List<MonthlyData> monthlyTrend;
  final List<CategoryData> categoryBreakdown;
  final List<StoreData> storeBreakdown;
  final double totalMonthly;
  final double totalYearly;
  
  ExpenseStats({
    required this.monthlyTrend,
    required this.categoryBreakdown,
    required this.storeBreakdown,
    required this.totalMonthly,
    required this.totalYearly,
  });
}

final statsProvider = StateNotifierProvider<StatsNotifier, ExpenseStats>((ref) {
  return StatsNotifier();
});

class StatsNotifier extends StateNotifier<ExpenseStats> {
  final Box<ShoppingList> _listBox = Hive.box<ShoppingList>('shopping_lists');
  final Box<Product> _productBox = Hive.box<Product>('products');

  StatsNotifier() : super(
    ExpenseStats(
      monthlyTrend: [],
      categoryBreakdown: [],
      storeBreakdown: [],
      totalMonthly: 0,
      totalYearly: 0,
    ),
  ) {
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    // Get all shopping lists
    final lists = _listBox.values.toList();
    
    // Calculate monthly trends (last 12 months)
    final monthlyMap = <String, double>{};
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final key = DateFormat('MMM yyyy').format(date);
      monthlyMap[key] = 0;
    }
    
    // Calculate category breakdown
    final categoryMap = <String, double>{};
    
    // Calculate store breakdown
    final storeMap = <String, double>{};
    
    double currentMonthTotal = 0;
    double yearlyTotal = 0;
    
    for (final list in lists) {
      final listMonth = DateTime(list.createdAt.year, list.createdAt.month);
      
      double listTotal = 0;
      for (final item in list.items) {
        listTotal += item.estimatedPrice;
        
        // Get category from product
        try {
          final product = _productBox.get(item.productId);
          if (product != null) {
            categoryMap[product.category] = (categoryMap[product.category] ?? 0) + item.estimatedPrice;
          }
        } catch (e) {
          // Product not found, skip category tracking
        }
      }
      
      // Add to store breakdown
      final storeName = list.storeName ?? 'Unknown Store';
      storeMap[storeName] = (storeMap[storeName] ?? 0) + listTotal;
      
      // Add to monthly trend
      final monthKey = DateFormat('MMM yyyy').format(list.createdAt);
      if (monthlyMap.containsKey(monthKey)) {
        monthlyMap[monthKey] = monthlyMap[monthKey]! + listTotal;
      }
      
      // Track current month and yearly totals
      if (listMonth == currentMonth) {
        currentMonthTotal += listTotal;
      }
      
      // Check if within last year
      final monthsDifference = (now.year - list.createdAt.year) * 12 + 
                               (now.month - list.createdAt.month);
      if (monthsDifference <= 12) {
        yearlyTotal += listTotal;
      }
    }
    
    // Convert to sorted lists
    final monthlyTrend = monthlyMap.entries
        .map((e) => MonthlyData(month: e.key, total: e.value))
        .toList();
    
    final categoryList = categoryMap.entries
        .map((e) => CategoryData(category: e.key, total: e.value))
        .toList();
    categoryList.sort((a, b) => b.total.compareTo(a.total));
    final categoryBreakdown = categoryList;
    
    final storeBreakdownList = storeMap.entries
        .map((e) => StoreData(store: e.key, total: e.value))
        .toList();
    storeBreakdownList.sort((a, b) => b.total.compareTo(a.total));
    final storeBreakdown = storeBreakdownList;
    
    state = ExpenseStats(
      monthlyTrend: monthlyTrend,
      categoryBreakdown: categoryBreakdown,
      storeBreakdown: storeBreakdown,
      totalMonthly: currentMonthTotal,
      totalYearly: yearlyTotal,
    );
  }

  List<CategoryData> sortByTotal(List<CategoryData> categories) {
    final sorted = List<CategoryData>.from(categories);
    sorted.sort((a, b) => b.total.compareTo(a.total));
    return sorted;
  }

  List<StoreData> getTopStores({int limit = 5}) {
    final sorted = List<StoreData>.from(state.storeBreakdown);
    sorted.sort((a, b) => b.total.compareTo(a.total));
    return sorted.take(limit).toList();
  }

  ExpenseStats getMonthlyStats(int month, int year) {
    final lists = _listBox.values
        .where((l) => l.createdAt.month == month && l.createdAt.year == year)
        .toList();

    final categoryMap = <String, double>{};
    final storeMap = <String, double>{};
    double total = 0;

    for (final list in lists) {
      double listTotal = 0;
      for (final item in list.items) {
        listTotal += item.estimatedPrice;
        try {
          final product = _productBox.get(item.productId);
          if (product != null) {
            categoryMap[product.category] =
                (categoryMap[product.category] ?? 0) + item.estimatedPrice;
          }
        } catch (_) {}
      }
      final storeName = list.storeName ?? 'Unknown Store';
      storeMap[storeName] = (storeMap[storeName] ?? 0) + listTotal;
      total += listTotal;
    }

    final categoryList = categoryMap.entries
        .map((e) => CategoryData(category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final storeList = storeMap.entries
        .map((e) => StoreData(store: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return ExpenseStats(
      monthlyTrend: state.monthlyTrend,
      categoryBreakdown: categoryList,
      storeBreakdown: storeList,
      totalMonthly: total,
      totalYearly: state.totalYearly,
    );
  }

  List<CategoryData> getCategoryBreakdown() {
    return sortByTotal(state.categoryBreakdown);
  }

  List<StoreData> getStoreTotals() {
    return getTopStores();
  }

  void refresh() {
    _loadStats();
  }
}
