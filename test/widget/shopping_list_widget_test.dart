import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:buyWMe/providers/shopping_list_provider.dart';
import 'package:buyWMe/models/shopping_list.dart';
import 'package:buyWMe/models/shopping_item.dart';

void main() {
  group('Shopping List Widget Tests', () {
    testWidgets('ShoppingListNotifier can be created', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shoppingListProvider.notifier);
      expect(notifier, isA<ShoppingListNotifier>());
    });

    testWidgets('ShoppingListNotifier state changes trigger rebuild', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final lists = ref.watch(shoppingListProvider);
                return Text('Lists: ${lists.length}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Lists: 0'), findsOneWidget);

      container.read(shoppingListProvider.notifier).addList('Test List');

      await tester.pump();

      expect(find.text('Lists: 1'), findsOneWidget);
    });
  });
}