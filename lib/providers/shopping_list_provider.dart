import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, List<ShoppingList>>((ref) {
  return ShoppingListNotifier();
});

class ShoppingListNotifier extends StateNotifier<List<ShoppingList>> {
  final Box<ShoppingList> _box = Hive.box<ShoppingList>('shopping_lists');
  final _uuid = const Uuid();

  ShoppingListNotifier() : super([]) {
    _loadLists();
  }

  void _loadLists() {
    state = _box.values.toList();
  }

  void addList(String name, {double? budget, String? storeId, String? storeName}) {
    final list = ShoppingList(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      budget: budget,
      storeId: storeId,
      storeName: storeName,
    );
    _box.put(list.id, list);
    _loadLists();
  }

  void addListFromTemplate(String name, String template, {double? budget, String? storeId, String? storeName}) {
    final list = ShoppingList(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      budget: budget,
      storeId: storeId,
      storeName: storeName,
    );
    
    // Add template items
    final templateItems = _getTemplateItems(template);
    list.items.addAll(templateItems);
    
    _box.put(list.id, list);
    _loadLists();
  }

  List<ShoppingItem> _getTemplateItems(String template) {
    switch (template) {
      case 'Weekly Groceries':
        return [
          ShoppingItem(id: _uuid.v4(), productId: 'p1', name: 'Rice', quantity: 5, unit: 'kg', estimatedPrice: 250),
          ShoppingItem(id: _uuid.v4(), productId: 'p2', name: 'Eggs', quantity: 1, unit: 'dozen', estimatedPrice: 120),
          ShoppingItem(id: _uuid.v4(), productId: 'p3', name: 'Milk', quantity: 2, unit: 'L', estimatedPrice: 180),
          ShoppingItem(id: _uuid.v4(), productId: 'p4', name: 'Bread', quantity: 2, unit: 'pcs', estimatedPrice: 100),
          ShoppingItem(id: _uuid.v4(), productId: 'p5', name: 'Chicken', quantity: 1, unit: 'kg', estimatedPrice: 200),
        ];
      case 'Party Supplies':
        return [
          ShoppingItem(id: _uuid.v4(), productId: 'p6', name: 'Soft Drinks', quantity: 6, unit: 'bottles', estimatedPrice: 300),
          ShoppingItem(id: _uuid.v4(), productId: 'p7', name: 'Chips', quantity: 5, unit: 'packs', estimatedPrice: 250),
          ShoppingItem(id: _uuid.v4(), productId: 'p8', name: 'Paper Plates', quantity: 1, unit: 'pack', estimatedPrice: 80),
          ShoppingItem(id: _uuid.v4(), productId: 'p9', name: 'Cups', quantity: 1, unit: 'pack', estimatedPrice: 60),
        ];
      case 'Breakfast Essentials':
        return [
          ShoppingItem(id: _uuid.v4(), productId: 'p10', name: 'Coffee', quantity: 1, unit: 'pack', estimatedPrice: 150),
          ShoppingItem(id: _uuid.v4(), productId: 'p11', name: 'Sugar', quantity: 1, unit: 'kg', estimatedPrice: 80),
          ShoppingItem(id: _uuid.v4(), productId: 'p12', name: 'Butter', quantity: 1, unit: 'pack', estimatedPrice: 120),
          ShoppingItem(id: _uuid.v4(), productId: 'p13', name: 'Cereal', quantity: 1, unit: 'box', estimatedPrice: 200),
        ];
      default:
        return [];
    }
  }

  void deleteList(String id) {
    _box.delete(id);
    _loadLists();
  }

  void addItem(String listId, ShoppingItem item) {
    final list = _box.get(listId);
    if (list != null) {
      list.items.add(item);
      list.save();
      _loadLists();
    }
  }

  void toggleItem(String listId, String itemId) {
    final list = _box.get(listId);
    if (list != null) {
      final item = list.items.firstWhere((i) => i.id == itemId);
      item.isDone = !item.isDone;
      list.save();
      _loadLists();
    }
  }

  void deleteItem(String listId, String itemId) {
    final list = _box.get(listId);
    if (list != null) {
      list.items.removeWhere((i) => i.id == itemId);
      list.save();
      _loadLists();
    }
  }
}
