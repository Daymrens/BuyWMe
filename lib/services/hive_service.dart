import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/store_product.dart';
import '../models/store.dart';
import '../models/price_entry.dart';
import '../models/favorite_item.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(ShoppingListAdapter());
    Hive.registerAdapter(StoreProductAdapter());
    Hive.registerAdapter(StoreAdapter());
    Hive.registerAdapter(PriceEntryAdapter());
    Hive.registerAdapter(FavoriteItemAdapter());
    
    // Open boxes
    await Hive.openBox<Product>('products');
    await Hive.openBox<ShoppingList>('shopping_lists');
    await Hive.openBox<Store>('stores');
    await Hive.openBox<PriceEntry>('price_entries');
    await Hive.openBox<FavoriteItem>('favorites');
  }
}
