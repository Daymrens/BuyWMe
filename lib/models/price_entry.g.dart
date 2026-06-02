// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceEntryAdapter extends TypeAdapter<PriceEntry> {
  @override
  final int typeId = 5;

  @override
  PriceEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceEntry(
      productId: fields[0] as String,
      storeId: fields[1] as String,
      price: fields[2] as double,
      date: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PriceEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.storeId)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
