import 'dart:typed_data';
import 'package:hive/hive.dart';
part 'uploaded_file.g.dart';

@HiveType(typeId: 0)
class UploadedFile extends HiveObject {
  @HiveField(0)
  final int fileId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int size;

  @HiveField(3)
  final String path;

  @HiveField(4)
  final String type;

  // keep base64 OPTIONAL (for backward compatibility)
  @HiveField(5)
  final String? thumbnail;

  @HiveField(6)
  final String? caption;

  // ✅ NEW: persisted thumbnail cache
  @HiveField(7)
  final Uint8List? thumbBytes;

  UploadedFile({
    required this.fileId,
    required this.name,
    required this.size,
    required this.path,
    required this.type,
    this.thumbnail,
    this.caption,
    this.thumbBytes,
  });
}