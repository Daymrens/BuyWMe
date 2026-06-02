import 'package:hive/hive.dart';

part 'store_product.g.dart';

@HiveType(typeId: 3)
class StoreProduct extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String productName;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late String stockStatus;

  @HiveField(4)
  late DateTime updatedAt;

  StoreProduct({
    required this.productId,
    required this.productName,
    required this.price,
    required this.stockStatus,
    required this.updatedAt,
  });
}
