import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/price_entry.dart';

final priceTrackerProvider = StateNotifierProvider<PriceTrackerNotifier, List<PriceEntry>>((ref) {
  return PriceTrackerNotifier();
});

class PriceTrackerNotifier extends StateNotifier<List<PriceEntry>> {
  final Box<PriceEntry> _box = Hive.box<PriceEntry>('price_entries');

  PriceTrackerNotifier() : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    state = _box.values.toList();
  }

  void addEntry(String productId, String storeId, double price) {
    final entry = PriceEntry(
      productId: productId,
      storeId: storeId,
      price: price,
      date: DateTime.now(),
    );
    _box.add(entry);
    _loadEntries();
  }

  List<PriceEntry> getEntriesForProduct(String productId) {
    return state.where((e) => e.productId == productId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
