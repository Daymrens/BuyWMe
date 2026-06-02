import 'package:hive/hive.dart';
import 'shopping_item.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 2)
class ShoppingList extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late List<ShoppingItem> items;

  @HiveField(4)
  double? budget;

  @HiveField(5)
  String? storeId;

  @HiveField(6)
  String? storeName;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    List<ShoppingItem>? items,
    this.budget,
    this.storeId,
    this.storeName,
  }) : items = items ?? [];
}
