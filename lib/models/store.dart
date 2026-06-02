import 'package:hive/hive.dart';
import 'store_product.dart';

part 'store.g.dart';

@HiveType(typeId: 4)
class Store extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? location;

  @HiveField(3)
  late List<StoreProduct> inventory;

  @HiveField(4)
  bool isFavorite;

  Store({
    required this.id,
    required this.name,
    this.location,
    List<StoreProduct>? inventory,
    this.isFavorite = false,
  }) : inventory = inventory ?? [];

  // Computed property for product count
  int get productCount => inventory.length;

  // Alias for location to match UI expectations
  String? get address => location;
  set address(String? value) => location = value;
}
