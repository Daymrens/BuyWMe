import 'package:flutter_test/flutter_test.dart';
import 'package:buyWMe/models/shopping_list.dart';
import 'package:buyWMe/models/shopping_item.dart';

void main() {
  group('ShoppingList', () {
    test('creates list with all required fields', () {
      final now = DateTime.now();
      const item = ShoppingItem(
        id: 'item-1',
        productId: 'product-1',
        name: 'Test Item',
        quantity: 1,
        unit: 'pcs',
        estimatedPrice: 50.0,
      );

      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: now,
        items: [item],
        budget: 100.0,
        storeId: 'store-1',
        storeName: 'Test Store',
      );

      expect(list.id, 'list-1');
      expect(list.name, 'Test List');
      expect(list.createdAt, now);
      expect(list.items.length, 1);
      expect(list.budget, 100.0);
      expect(list.storeId, 'store-1');
      expect(list.storeName, 'Test Store');
    });

    test('default items is empty list', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
      );

      expect(list.items, isEmpty);
    });

    test('default budget, storeId, storeName are null', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
      );

      expect(list.budget, isNull);
      expect(list.storeId, isNull);
      expect(list.storeName, isNull);
    });

    test('total estimated price calculation', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Item 1', quantity: 2, unit: 'kg', estimatedPrice: 50.0),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Item 2', quantity: 3, unit: 'pcs', estimatedPrice: 30.0),
        ],
      );

      final total = list.items.fold<double>(0, (sum, item) => sum + (item.quantity * item.estimatedPrice));
      expect(total, 190.0);
    });

    test('completed items count', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Item 1', quantity: 1, unit: 'pcs', estimatedPrice: 10.0, isDone: true),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Item 2', quantity: 1, unit: 'pcs', estimatedPrice: 20.0, isDone: false),
          ShoppingItem(id: 'i3', productId: 'p3', name: 'Item 3', quantity: 1, unit: 'pcs', estimatedPrice: 30.0, isDone: true),
        ],
      );

      final completed = list.items.where((item) => item.isDone).length;
      expect(completed, 2);
    });

    test('remaining items count', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Item 1', quantity: 1, unit: 'pcs', estimatedPrice: 10.0, isDone: true),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Item 2', quantity: 1, unit: 'pcs', estimatedPrice: 20.0, isDone: false),
        ],
      );

      final remaining = list.items.where((item) => !item.isDone).length;
      expect(remaining, 1);
    });
  });
}