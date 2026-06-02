import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/favorite_item.dart';

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<FavoriteItem>>((ref) {
  return FavoriteNotifier();
});

class FavoriteNotifier extends StateNotifier<List<FavoriteItem>> {
  final Box<FavoriteItem> _box = Hive.box<FavoriteItem>('favorites');
  final _uuid = const Uuid();

  FavoriteNotifier() : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final items = _box.values.toList();
    // Sort by addedCount descending, then by lastAdded descending
    items.sort((a, b) {
      final countDiff = b.addedCount.compareTo(a.addedCount);
      if (countDiff != 0) return countDiff;
      return b.lastAdded.compareTo(a.lastAdded);
    });
    state = items;
  }

  void addFavorite({
    required String itemName,
    String? store,
    double? price,
  }) {
    final itemNameLower = itemName.toLowerCase().trim();
    
    // Check if favorite already exists (case-insensitive)
    final existingIndex = state.indexWhere(
      (item) => item.itemName.toLowerCase() == itemNameLower,
    );

    if (existingIndex >= 0) {
      // Update existing favorite
      final existing = state[existingIndex];
      existing.addedCount += 1;
      existing.lastAdded = DateTime.now();
      if (store != null) existing.store = store;
      if (price != null) existing.price = price;
      existing.save();
    } else {
      // Create new favorite
      final favorite = FavoriteItem(
        id: _uuid.v4(),
        itemName: itemName,
        store: store,
        price: price,
        addedCount: 1,
        lastAdded: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _box.put(favorite.id, favorite);
    }
    
    _loadFavorites();
  }

  void removeFavorite(String favoriteId) {
    _box.delete(favoriteId);
    _loadFavorites();
  }

  void toggleFavorite({
    required String itemName,
    String? store,
    double? price,
  }) {
    final itemNameLower = itemName.toLowerCase().trim();
    final existingIndex = state.indexWhere(
      (item) => item.itemName.toLowerCase() == itemNameLower,
    );

    if (existingIndex >= 0) {
      // Remove from favorites
      removeFavorite(state[existingIndex].id);
    } else {
      // Add to favorites
      addFavorite(itemName: itemName, store: store, price: price);
    }
  }

  bool isFavorite(String itemName) {
    final itemNameLower = itemName.toLowerCase().trim();
    return state.any((item) => item.itemName.toLowerCase() == itemNameLower);
  }

  FavoriteItem? getFavorite(String itemName) {
    final itemNameLower = itemName.toLowerCase().trim();
    try {
      return state.firstWhere(
        (item) => item.itemName.toLowerCase() == itemNameLower,
      );
    } catch (e) {
      return null;
    }
  }

  List<FavoriteItem> getFavorites() {
    return state;
  }

  void incrementAddedCount(String favoriteId) {
    final favorite = _box.get(favoriteId);
    if (favorite != null) {
      favorite.addedCount += 1;
      favorite.lastAdded = DateTime.now();
      favorite.save();
      _loadFavorites();
    }
  }
}
