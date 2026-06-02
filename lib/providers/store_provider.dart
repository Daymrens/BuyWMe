import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/store.dart';
import '../models/store_product.dart';

final storeProvider = StateNotifierProvider<StoreNotifier, List<Store>>((ref) {
  return StoreNotifier();
});

class StoreNotifier extends StateNotifier<List<Store>> {
  final Box<Store> _box = Hive.box<Store>('stores');
  final _uuid = const Uuid();

  StoreNotifier() : super([]) {
    _loadStores();
  }

  void _loadStores() {
    state = _box.values.toList();
  }

  void addStore(String name, {String? address}) {
    final store = Store(
      id: _uuid.v4(),
      name: name,
      location: address,
    );
    _box.put(store.id, store);
    _loadStores();
  }

  void toggleFavorite(String id) {
    final store = _box.get(id);
    if (store != null) {
      store.isFavorite = !store.isFavorite;
      store.save();
      _loadStores();
    }
  }

  void refresh() {
    _loadStores();
  }

  void deleteStore(String id) {
    _box.delete(id);
    _loadStores();
  }

  void addProduct(String storeId, StoreProduct product) {
    final store = _box.get(storeId);
    if (store != null) {
      store.inventory.add(product);
      store.save();
      _loadStores();
    }
  }

  void updateProduct(String storeId, String productId, double price, String stockStatus) {
    final store = _box.get(storeId);
    if (store != null) {
      final product = store.inventory.firstWhere((p) => p.productId == productId);
      product.price = price;
      product.stockStatus = stockStatus;
      product.updatedAt = DateTime.now();
      store.save();
      _loadStores();
    }
  }
}
