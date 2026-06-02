import 'package:hive/hive.dart';

part 'favorite_item.g.dart';

@HiveType(typeId: 7)
class FavoriteItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String itemName;

  @HiveField(2)
  String? store;

  @HiveField(3)
  double? price;

  @HiveField(4)
  late int addedCount;

  @HiveField(5)
  late DateTime lastAdded;

  @HiveField(6)
  late DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.itemName,
    this.store,
    this.price,
    required this.addedCount,
    required this.lastAdded,
    required this.createdAt,
  });
}
