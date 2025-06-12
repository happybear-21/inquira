// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arxiv_paper.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArxivPaperAdapter extends TypeAdapter<ArxivPaper> {
  @override
  final int typeId = 1;

  @override
  ArxivPaper read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArxivPaper(
      id: fields[0] as String,
      title: fields[1] as String,
      authors: (fields[2] as List).cast<String>(),
      abstract: fields[3] as String,
      pdfUrl: fields[4] as String,
      publishedDate: fields[5] as DateTime,
      categories: (fields[6] as List).cast<String>(),
      primaryCategory: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ArxivPaper obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.authors)
      ..writeByte(3)
      ..write(obj.abstract)
      ..writeByte(4)
      ..write(obj.pdfUrl)
      ..writeByte(5)
      ..write(obj.publishedDate)
      ..writeByte(6)
      ..write(obj.categories)
      ..writeByte(7)
      ..write(obj.primaryCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArxivPaperAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
