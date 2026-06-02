import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? barcode;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late String unit;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    required this.category,
    required this.unit,
  });
}
