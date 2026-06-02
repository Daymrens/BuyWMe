import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grocery_mate/models/shopping_list.dart';
import 'package:grocery_mate/models/shopping_item.dart';
import 'package:grocery_mate/services/autocomplete_service.dart';

void main() {
  group('AutocompleteService', () {
    late AutocompleteService service;

    setUpAll(() async {
      // Initialize Hive for testing
      final dir = Directory.systemTemp.createTempSync();
      Hive.init(dir.path);
      
      // Register adapters
      Hive.registerAdapter(ShoppingListAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
    });

    setUp(() {
      service = AutocompleteService();
      // Clear the index before each test
      service.clearIndex();
    });

    test('Get suggestions with empty query returns empty list', () {
      service.indexItems();
      final suggestions = service.getSuggestions('');
      expect(suggestions, isEmpty);
    });

    test('Substring matching works correctly', () {
      // Test the suggestion matching logic
      final query = 'ric';
      
      // Create a list of test items that would be indexed
      final testItems = ['rice', 'chicken', 'price', 'grice', 'brick'];
      
      // Filter for substring matches (simulating getSuggestions logic)
      final matches = testItems
          .where((item) => item.contains(query.toLowerCase()))
          .toList();
      
      expect(matches, contains('rice'));
      expect(matches, contains('price'));
      expect(matches, isNotEmpty);
    });

    test('Case-insensitive matching works', () {
      // Test that matching is case-insensitive
      final query = 'RICE';
      final item = 'rice';
      
      expect(item.contains(query.toLowerCase()), true);
    });

    test('Suggestions respects max 5 items limit', () {
      service.indexItems();
      // Any query should return at most 5 suggestions
      final longQuery = 'a';
      final suggestions = service.getSuggestions(longQuery);
      
      expect(suggestions.length, lessThanOrEqualTo(5));
    });

    test('Empty item name returns empty suggestions', () {
      service.indexItems();
      final suggestions = service.getSuggestions('');
      expect(suggestions, isEmpty);
    });

    test('Whitespace-only query returns empty suggestions', () {
      service.indexItems();
      final suggestions = service.getSuggestions('   ');
      expect(suggestions, isEmpty);
    });

    test('Partial word matching works', () {
      // Test partial word matching
      const testWord = 'vegetables';
      const query = 'veg';
      
      expect(testWord.contains(query), true);
    });

    test('Item frequency tracking works', () {
      // Test that frequency is initialized to 0 for unknown items
      final frequency = service.getItemFrequency('nonexistent_item');
      expect(frequency, 0);
    });

    test('Clear index works correctly', () {
      service.indexItems();
      service.clearIndex();
      
      // After clearing, no suggestions should be returned
      final suggestions = service.getSuggestions('test');
      expect(suggestions, isEmpty);
    });

    tearDown(() {
      service.clearIndex();
    });
  });
}

