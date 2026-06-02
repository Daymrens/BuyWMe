// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreProductAdapter extends TypeAdapter<StoreProduct> {
  @override
  final int typeId = 3;

  @override
  StoreProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreProduct(
      productId: fields[0] as String,
      productName: fields[1] as String,
      price: fields[2] as double,
      stockStatus: fields[3] as String,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StoreProduct obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.stockStatus)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
