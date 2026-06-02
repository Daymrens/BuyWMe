import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../models/favorite_item.dart';

class AutocompleteService {
  static final AutocompleteService _instance = AutocompleteService._internal();
  
  late Map<String, int> _itemFrequency;
  late List<String> _indexedItems;
  late Set<String> _favoriteItemNames;

  factory AutocompleteService() {
    return _instance;
  }
  
  AutocompleteService._internal() {
    _itemFrequency = {};
    _indexedItems = [];
    _favoriteItemNames = {};
  }

  /// Index all item names from shopping lists in Hive and mark favorites
  void indexItems() {
    _itemFrequency.clear();
    _indexedItems.clear();
    _favoriteItemNames.clear();
    
    try {
      final box = Hive.box<ShoppingList>('shopping_lists');
      
      for (final list in box.values) {
        for (final item in list.items) {
          final name = item.name.toLowerCase();
          _itemFrequency[name] = (_itemFrequency[name] ?? 0) + 1;
        }
      }
      
      // Load favorites
      try {
        final favBox = Hive.box<FavoriteItem>('favorites');
        for (final fav in favBox.values) {
          _favoriteItemNames.add(fav.itemName.toLowerCase());
        }
      } catch (e) {
        // Favorites box might not be initialized yet
      }
      
      _indexedItems = _itemFrequency.keys.toList();
    } catch (e) {
      // Handle case where Hive box is not initialized
      _itemFrequency = {};
      _indexedItems = [];
    }
  }

  /// Get suggestions for a query with fuzzy matching (substring match)
  /// Returns top 5 most-added items first, with favorites prioritized
  List<String> getSuggestions(String query) {
    if (query.isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase().trim();
    
    // Find all items that contain the query (substring match)
    final matches = <String>[];
    
    for (final item in _indexedItems) {
      if (item.contains(queryLower)) {
        matches.add(item);
      }
    }

    // Sort by: favorites first, then frequency, then substring match position
    matches.sort((a, b) {
      final aIsFavorite = _favoriteItemNames.contains(a);
      final bIsFavorite = _favoriteItemNames.contains(b);
      
      // Favorites first
      if (aIsFavorite != bIsFavorite) {
        return aIsFavorite ? -1 : 1;
      }
      
      // Then by frequency
      final freqDiff = (_itemFrequency[b] ?? 0) - (_itemFrequency[a] ?? 0);
      if (freqDiff != 0) return freqDiff;
      
      // If same frequency, prioritize matches at the beginning
      final aPos = a.indexOf(queryLower);
      final bPos = b.indexOf(queryLower);
      return aPos.compareTo(bPos);
    });

    // Return top 5 suggestions
    return matches.take(5).toList();
  }

  /// Get frequency count for an item (for display purposes)
  int getItemFrequency(String itemName) {
    return _itemFrequency[itemName.toLowerCase()] ?? 0;
  }

  /// Check if item is a favorite
  bool isFavorite(String itemName) {
    return _favoriteItemNames.contains(itemName.toLowerCase());
  }

  /// Clear the index
  void clearIndex() {
    _itemFrequency.clear();
    _indexedItems.clear();
    _favoriteItemNames.clear();
  }
}

