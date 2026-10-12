import 'package:flutter/material.dart';

class EncryptedFile {
  final String id;
  final String name; // الاسم كاملاً مع .enc (مثل: video.mp4.enc)
  final String originalName; // الاسم بدون .enc (مثل: video.mp4)
  final String path;
  final int size;
  final DateTime encryptionDate;
  final FileType originalType; // نوع الملف الأصلي المستخرج من الاسم
  final String? thumbnailPath;
  final String? description;

  EncryptedFile({
    required this.id,
    required this.name,
    required this.originalName,
    required this.path,
    required this.size,
    required this.encryptionDate,
    required this.originalType,
    this.thumbnailPath,
    this.description,
  });

  // الحصول على الامتداد الأصلي
  String get originalExtension {
    if (originalName.contains('.')) {
      return originalName.substring(originalName.lastIndexOf('.')).toLowerCase();
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalName': originalName,
      'path': path,
      'size': size,
      'encryptionDate': encryptionDate.toIso8601String(),
      'originalType': originalType.index,
      'thumbnailPath': thumbnailPath,
      'description': description,
    };
  }

  factory EncryptedFile.fromMap(Map<String, dynamic> map) {
    return EncryptedFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      originalName: map['originalName'] ?? '',
      path: map['path'] ?? '',
      size: map['size'] ?? 0,
      encryptionDate: DateTime.parse(map['encryptionDate']),
      originalType: FileType.values[map['originalType'] ?? 4],
      thumbnailPath: map['thumbnailPath'],
      description: map['description'],
    );
  }
}

enum FileType {
  video,
  image,
  document,
  audio,
  other,
}

class FileTypeInfo {
  static Color getColor(FileType type) {
    switch (type) {
      case FileType.video:
        return Colors.red;
      case FileType.image:
        return Colors.blue;
      case FileType.document:
        return Colors.green;
      case FileType.audio:
        return Colors.purple;
      case FileType.other:
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(FileType type) {
    switch (type) {
      case FileType.video:
        return Icons.videocam;
      case FileType.image:
        return Icons.photo;
      case FileType.document:
        return Icons.description;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.other:
      default:
        return Icons.insert_drive_file;
    }
  }

  static String getName(FileType type) {
    switch (type) {
      case FileType.video:
        return 'فيديو';
      case FileType.image:
        return 'صورة';
      case FileType.document:
        return 'مستند';
      case FileType.audio:
        return 'صوت';
      case FileType.other:
      default:
        return 'آخر';
    }
  }

  // دالة لاستخراج نوع الملف من الامتداد
  static FileType getTypeFromExtension(String extension) {
    extension = extension.toLowerCase();
    
    const videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.mpg', '.mpeg', '.3gp', '.webm', '.m4v'];
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico', '.tiff', '.heic'];
    const documentExtensions = ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.xlsx', '.pptx', '.csv', '.odt', '.ods', '.ppt'];
    const audioExtensions = ['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma', '.opus', '.m4b'];
    
    if (videoExtensions.contains(extension)) {
      return FileType.video;
    } else if (imageExtensions.contains(extension)) {
      return FileType.image;
    } else if (documentExtensions.contains(extension)) {
      return FileType.document;
    } else if (audioExtensions.contains(extension)) {
      return FileType.audio;
    } else {
      return FileType.other;
    }
  }
}

class FileCategory {
  final FileType type;
  final String name;
  final IconData icon;
  final Color color;
  int count;

  FileCategory({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
    this.count = 0,
  });
}