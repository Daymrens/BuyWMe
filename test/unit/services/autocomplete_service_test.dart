import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:buyWMe/models/shopping_list.dart';
import 'package:buyWMe/models/shopping_item.dart';
import 'package:buyWMe/models/favorite_item.dart';
import 'package:buyWMe/services/autocomplete_service.dart';

class MockShoppingListBox extends Mock implements Box<ShoppingList> {}
class MockFavoriteBox extends Mock implements Box<FavoriteItem> {}

void main() {
  late MockShoppingListBox mockShoppingListBox;
  late MockFavoriteBox mockFavoriteBox;
  late AutocompleteService autocompleteService;

  setUpAll(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ShoppingListAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(FavoriteItemAdapter());
  });

  setUp(() {
    mockShoppingListBox = MockShoppingListBox();
    mockFavoriteBox = MockFavoriteBox();
    autocompleteService = AutocompleteService();
  });

  group('AutocompleteService', () {
    test('getSuggestions returns empty list for empty query', () {
      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('');
      expect(suggestions, isEmpty);
    });

    test('getSuggestions returns empty list when no items indexed', () {
      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('apple');
      expect(suggestions, isEmpty);
    });

    test('indexItems loads items from shopping lists', () {
      final list1 = ShoppingList(
        id: '1',
        name: 'List 1',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Apple', quantity: 5, unit: 'kg', estimatedPrice: 50),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Banana', quantity: 3, unit: 'kg', estimatedPrice: 30),
        ],
      );
      final list2 = ShoppingList(
        id: '2',
        name: 'List 2',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i3', productId: 'p1', name: 'Apple', quantity: 2, unit: 'kg', estimatedPrice: 20),
          ShoppingItem(id: 'i4', productId: 'p3', name: 'Orange', quantity: 4, unit: 'kg', estimatedPrice: 40),
        ],
      );

      when(() => mockShoppingListBox.values).thenReturn([list1, list2]);

      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('app');

      expect(suggestions, contains('apple'));
      expect(autocompleteService.getItemFrequency('apple'), 2);
      expect(autocompleteService.getItemFrequency('banana'), 1);
      expect(autocompleteService.getItemFrequency('orange'), 1);
    });

    test('getSuggestions prioritizes favorites', () {
      final list = ShoppingList(
        id: '1',
        name: 'List 1',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Apple', quantity: 5, unit: 'kg', estimatedPrice: 50),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Banana', quantity: 10, unit: 'kg', estimatedPrice: 30),
        ],
      );
      final favorite = FavoriteItem(id: 'f1', itemName: 'Banana', addedAt: DateTime.now());

      when(() => mockShoppingListBox.values).thenReturn([list]);
      when(() => mockFavoriteBox.values).thenReturn([favorite]);

      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('');

      expect(suggestions.first, 'banana');
    });

    test('getSuggestions sorts by frequency', () {
      final list = ShoppingList(
        id: '1',
        name: 'List 1',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Apple', quantity: 5, unit: 'kg', estimatedPrice: 50),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Apple', quantity: 3, unit: 'kg', estimatedPrice: 30),
          ShoppingItem(id: 'i3', productId: 'p3', name: 'Banana', quantity: 1, unit: 'kg', estimatedPrice: 20),
        ],
      );

      when(() => mockShoppingListBox.values).thenReturn([list]);

      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('');

      expect(suggestions.first, 'apple');
      expect(suggestions.last, 'banana');
    });

    test('getSuggestions sorts by substring position when frequency equal', () {
      final list = ShoppingList(
        id: '1',
        name: 'List 1',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Green Apple', quantity: 5, unit: 'kg', estimatedPrice: 50),
          ShoppingItem(id: 'i2', productId: 'p2', name: 'Apple Pie', quantity: 5, unit: 'kg', estimatedPrice: 30),
        ],
      );

      when(() => mockShoppingListBox.values).thenReturn([list]);

      autocompleteService.indexItems();
      final suggestions = autocompleteService.getSuggestions('apple');

      expect(suggestions.first, 'apple pie');
    });

    test('isFavorite returns true for favorited items', () {
      final favorite = FavoriteItem(id: 'f1', itemName: 'Apple', addedAt: DateTime.now());
      when(() => mockFavoriteBox.values).thenReturn([favorite]);
      when(() => mockShoppingListBox.values).thenReturn([]);

      autocompleteService.indexItems();

      expect(autocompleteService.isFavorite('Apple'), true);
      expect(autocompleteService.isFavorite('apple'), true);
      expect(autocompleteService.isFavorite('Banana'), false);
    });

    test('clearIndex resets all data', () {
      final list = ShoppingList(
        id: '1',
        name: 'List 1',
        createdAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'i1', productId: 'p1', name: 'Apple', quantity: 5, unit: 'kg', estimatedPrice: 50),
        ],
      );
      when(() => mockShoppingListBox.values).thenReturn([list]);

      autocompleteService.indexItems();
      expect(autocompleteService.getItemFrequency('apple'), 1);

      autocompleteService.clearIndex();
      expect(autocompleteService.getItemFrequency('apple'), 0);
      expect(autocompleteService.getSuggestions('apple'), isEmpty);
    });
  });
}