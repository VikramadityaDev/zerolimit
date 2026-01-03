// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uploaded_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadedFileAdapter extends TypeAdapter<UploadedFile> {
  @override
  final int typeId = 0;

  @override
  UploadedFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadedFile(
      fileId: fields[0] as int,
      name: fields[1] as String,
      size: fields[2] as int,
      path: fields[3] as String,
      type: fields[4] as String,
      thumbnail: fields[5] as String?,
      caption: fields[6] as String?,
      thumbBytes: fields[7] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, UploadedFile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.fileId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.path)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.thumbnail)
      ..writeByte(6)
      ..write(obj.caption)
      ..writeByte(7)
      ..write(obj.thumbBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadedFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
