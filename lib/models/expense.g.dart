// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      childName: fields[1] as String,
      paymentDate: fields[2] as DateTime,
      businessName: fields[3] as String,
      subject: fields[4] as String,
      instructor: fields[5] as String,
      detail: fields[6] as String,
      classType: fields[7] as String,
      paymentMethod: fields[8] as String,
      cardName: fields[9] as String?,
      amount: fields[10] as int,
      cancellationAmount: fields[11] as int,
      isRefunded: fields[12] as bool,
      memo: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.childName)
      ..writeByte(2)
      ..write(obj.paymentDate)
      ..writeByte(3)
      ..write(obj.businessName)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.instructor)
      ..writeByte(6)
      ..write(obj.detail)
      ..writeByte(7)
      ..write(obj.classType)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.cardName)
      ..writeByte(10)
      ..write(obj.amount)
      ..writeByte(11)
      ..write(obj.cancellationAmount)
      ..writeByte(12)
      ..write(obj.isRefunded)
      ..writeByte(13)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
