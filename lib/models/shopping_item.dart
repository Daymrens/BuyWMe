import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 1)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String productId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late double quantity;

  @HiveField(4)
  late String unit;

  @HiveField(5)
  late double estimatedPrice;

  @HiveField(6)
  late bool isDone;

  ShoppingItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.estimatedPrice,
    this.isDone = false,
  });
}
