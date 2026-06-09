import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:buyWMe/models/shopping_list.dart';
import 'package:buyWMe/models/shopping_item.dart';
import 'package:buyWMe/providers/shopping_list_provider.dart';

class MockBox extends Mock implements Box<ShoppingList> {}

void main() {
  late MockBox mockBox;
  late ShoppingListNotifier notifier;

  setUpAll(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ShoppingListAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
  });

  setUp(() {
    mockBox = MockBox();
    notifier = ShoppingListNotifier();
  });

  group('ShoppingListNotifier', () {
    test('initial state is empty list', () {
      expect(notifier.state, isEmpty);
    });

    test('addList creates and adds a new shopping list', () {
      notifier.addList('Test List', budget: 100.0);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Test List');
      expect(notifier.state.first.budget, 100.0);
      expect(notifier.state.first.items, isEmpty);
      expect(notifier.state.first.id, isNotEmpty);
    });

    test('addListFromTemplate creates list with template items', () {
      notifier.addListFromTemplate('Weekly List', 'Weekly Groceries');

      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Weekly List');
      expect(notifier.state.first.items.length, 6);
      expect(notifier.state.first.items.first.name, 'Rice');
    });

    test('deleteList removes the list', () {
      notifier.addList('List to Delete');
      final id = notifier.state.first.id;

      notifier.deleteList(id);

      expect(notifier.state, isEmpty);
    });

    test('addItem adds item to existing list', () {
      notifier.addList('Test List');
      final listId = notifier.state.first.id;
      final item = ShoppingItem(
        id: const Uuid().v4(),
        productId: 'p1',
        name: 'Apple',
        quantity: 5,
        unit: 'kg',
        estimatedPrice: 50.0,
      );

      notifier.addItem(listId, item);

      expect(notifier.state.first.items.length, 1);
      expect(notifier.state.first.items.first.name, 'Apple');
    });

    test('toggleItem changes item isDone status', () {
      notifier.addList('Test List');
      final listId = notifier.state.first.id;
      final item = ShoppingItem(
        id: const Uuid().v4(),
        productId: 'p1',
        name: 'Apple',
        quantity: 5,
        unit: 'kg',
        estimatedPrice: 50.0,
        isDone: false,
      );
      notifier.addItem(listId, item);
      final itemId = item.id;

      notifier.toggleItem(listId, itemId);

      expect(notifier.state.first.items.first.isDone, true);

      notifier.toggleItem(listId, itemId);
      expect(notifier.state.first.items.first.isDone, false);
    });

    test('deleteItem removes item from list', () {
      notifier.addList('Test List');
      final listId = notifier.state.first.id;
      final item = ShoppingItem(
        id: const Uuid().v4(),
        productId: 'p1',
        name: 'Apple',
        quantity: 5,
        unit: 'kg',
        estimatedPrice: 50.0,
      );
      notifier.addItem(listId, item);
      final itemId = item.id;

      notifier.deleteItem(listId, itemId);

      expect(notifier.state.first.items, isEmpty);
    });

    test('refreshLists reloads from box', () {
      notifier.addList('List 1');
      notifier.addList('List 2');
      expect(notifier.state.length, 2);

      notifier.refreshLists();
      expect(notifier.state.length, 2);
    });
  });
}