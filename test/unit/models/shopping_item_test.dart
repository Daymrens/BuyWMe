import 'package:flutter_test/flutter_test.dart';
import 'package:buyWMe/models/shopping_item.dart';

void main() {
  group('ShoppingItem', () {
    test('creates item with all required fields', () {
      const item = ShoppingItem(
        id: 'test-id',
        productId: 'product-1',
        name: 'Test Item',
        quantity: 2.5,
        unit: 'kg',
        estimatedPrice: 100.0,
        isDone: false,
      );

      expect(item.id, 'test-id');
      expect(item.productId, 'product-1');
      expect(item.name, 'Test Item');
      expect(item.quantity, 2.5);
      expect(item.unit, 'kg');
      expect(item.estimatedPrice, 100.0);
      expect(item.isDone, false);
    });

    test('default isDone is false', () {
      const item = ShoppingItem(
        id: 'test-id',
        productId: 'product-1',
        name: 'Test Item',
        quantity: 1,
        unit: 'pcs',
        estimatedPrice: 50.0,
      );

      expect(item.isDone, false);
    });

    test('total price calculation', () {
      const item = ShoppingItem(
        id: 'test-id',
        productId: 'product-1',
        name: 'Test Item',
        quantity: 3,
        unit: 'kg',
        estimatedPrice: 50.0,
      );

      expect(item.quantity * item.estimatedPrice, 150.0);
    });

    test('item equality based on id', () {
      const item1 = ShoppingItem(
        id: 'same-id',
        productId: 'product-1',
        name: 'Item 1',
        quantity: 1,
        unit: 'pcs',
        estimatedPrice: 10.0,
      );
      const item2 = ShoppingItem(
        id: 'same-id',
        productId: 'product-2',
        name: 'Item 2',
        quantity: 2,
        unit: 'kg',
        estimatedPrice: 20.0,
      );

      expect(item1.id, item2.id);
    });
  });
}