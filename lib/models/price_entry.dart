import 'package:hive/hive.dart';

part 'price_entry.g.dart';

@HiveType(typeId: 5)
class PriceEntry extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String storeId;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late DateTime date;

  PriceEntry({
    required this.productId,
    required this.storeId,
    required this.price,
    required this.date,
  });
}
