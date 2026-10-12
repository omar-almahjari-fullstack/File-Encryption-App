import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'file_model.dart';

class FileManager {
  static const String encryptedFolder = '/storage/emulated/0/Encrypted_files';
  
  Future<void> initAppFolders() async {
    final dir = Directory(encryptedFolder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  // استخراج الامتداد الأصلي من اسم الملف المشفر
  static String _getOriginalExtension(String fileName) {
    // أمثلة:
    // video.mp4.enc → .mp4
    // image.jpg.enc → .jpg
    // document.pdf.enc → .pdf
    
    if (!fileName.toLowerCase().endsWith('.enc')) {
      return '';
    }
    
    // إزالة .enc
    String withoutEnc = fileName.substring(0, fileName.length - 4);
    
    // البحث عن آخر نقطة للحصول على الامتداد
    int lastDotIndex = withoutEnc.lastIndexOf('.');
    if (lastDotIndex == -1) {
      return '';
    }
    
    return withoutEnc.substring(lastDotIndex).toLowerCase();
  }

  // إنشاء كائن EncryptedFile من File
  Future<EncryptedFile> _createEncryptedFileFromFile(File file) async {
    final stats = await file.stat();
    final fileName = p.basename(file.path);
    
    // استخراج الاسم الأصلي (بدون .enc)
    String originalName = fileName;
    if (fileName.toLowerCase().endsWith('.enc')) {
      originalName = fileName.substring(0, fileName.length - 4);
    }
    
    // استخراج الامتداد الأصلي
    String originalExtension = _getOriginalExtension(fileName);
    
    // تحديد نوع الملف الأصلي
    FileType originalType = FileTypeInfo.getTypeFromExtension(originalExtension);
    
    // إذا كان النوع other، حاول تخمينه من الاسم
    if (originalType == FileType.other && originalName.isNotEmpty) {
      originalType = _determineFileTypeFromName(originalName);
    }
    
    // إنشاء معرف فريد
    final id = '${stats.modified.millisecondsSinceEpoch}_${fileName.hashCode}';
    
    return EncryptedFile(
      id: id,
      name: fileName,
      originalName: originalName,
      path: file.path,
      size: stats.size,
      encryptionDate: stats.modified,
      originalType: originalType,
      thumbnailPath: await _getThumbnailPath(file.path),
      description: await _extractFileDescription(file),
    );
  }

  // تخمين نوع الملف من الاسم
  static FileType _determineFileTypeFromName(String fileName) {
    String lowerName = fileName.toLowerCase();
    
    // كلمات مفتاحية للفيديو
    if (lowerName.contains('video') || lowerName.contains('vid') || 
        lowerName.contains('movie') || lowerName.contains('film') ||
        lowerName.contains('مقطع') || lowerName.contains('فيديو') ||
        lowerName.contains('تسجيل') || lowerName.contains('كاميرا') ||
        lowerName.contains('mp4') || lowerName.contains('avi') || 
        lowerName.contains('mkv') || lowerName.contains('mov')) {
      return FileType.video;
    }
    
    // كلمات مفتاحية للصور
    if (lowerName.contains('image') || lowerName.contains('img') || 
        lowerName.contains('photo') || lowerName.contains('pic') ||
        lowerName.contains('صورة') || lowerName.contains('صور') ||
        lowerName.contains('لقطة') || lowerName.contains('سكرين') ||
        lowerName.contains('jpg') || lowerName.contains('jpeg') || 
        lowerName.contains('png') || lowerName.contains('gif')) {
      return FileType.image;
    }
    
    // كلمات مفتاحية للمستندات
    if (lowerName.contains('doc') || lowerName.contains('pdf') || 
        lowerName.contains('word') || lowerName.contains('excel') ||
        lowerName.contains('powerpoint') || lowerName.contains('مستند') ||
        lowerName.contains('وثيقة') || lowerName.contains('عرض') ||
        lowerName.contains('تقرير') || lowerName.contains('بحث') ||
        lowerName.contains('txt') || lowerName.contains('rtf') || 
        lowerName.contains('docx') || lowerName.contains('xlsx')) {
      return FileType.document;
    }
    
    // كلمات مفتاحية للصوت
    if (lowerName.contains('audio') || lowerName.contains('sound') || 
        lowerName.contains('music') || lowerName.contains('mp3') ||
        lowerName.contains('صوت') || lowerName.contains('اغنية') ||
        lowerName.contains('أغنية') || lowerName.contains('تسجيل صوتي') ||
        lowerName.contains('موسيقى') || lowerName.contains('نغمه') ||
        lowerName.contains('wav') || lowerName.contains('ogg') || 
        lowerName.contains('flac') || lowerName.contains('aac')) {
      return FileType.audio;
    }
    
    return FileType.other;
  }

  // الحصول على جميع الملفات المشفرة
  Future<List<EncryptedFile>> getAllFiles() async {
    await initAppFolders();
    final dir = Directory(encryptedFolder);
    
    if (!await dir.exists()) {
      return [];
    }
    
    final List<FileSystemEntity> files = await dir.list().toList();
    final List<EncryptedFile> encryptedFiles = [];
    
    for (final file in files) {
      if (file is File && file.path.toLowerCase().endsWith('.enc')) {
        try {
          final encryptedFile = await _createEncryptedFileFromFile(file);
          encryptedFiles.add(encryptedFile);
        } catch (e) {
          print('خطأ في قراءة الملف: ${file.path} - $e');
        }
      }
    }
    
    // ترتيب من الأحدث إلى الأقدم
    encryptedFiles.sort((a, b) => b.encryptionDate.compareTo(a.encryptionDate));
    
    return encryptedFiles;
  }

  // الحصول على الملفات حسب النوع
  Future<List<EncryptedFile>> getFilesByType(FileType type) async {
    final allFiles = await getAllFiles();
    return allFiles.where((file) => file.originalType == type).toList();
  }

  // الحصول على الملفات الأخيرة
  Future<List<EncryptedFile>> getRecentFiles({int limit = 10}) async {
    final allFiles = await getAllFiles();
    return allFiles.take(limit).toList();
  }

  // الحصول على إحصائيات
  Future<Map<FileType, int>> getFileStats() async {
    final files = await getAllFiles();
    Map<FileType, int> stats = {
      FileType.video: 0,
      FileType.image: 0,
      FileType.document: 0,
      FileType.audio: 0,
      FileType.other: 0,
    };
    
    for (var file in files) {
      stats[file.originalType] = (stats[file.originalType] ?? 0) + 1;
    }
    
    return stats;
  }

  // دوال مساعدة
  Future<String?> _getThumbnailPath(String filePath) async {
    // يمكن تنفيذ هذا لاحقاً
    return null;
  }

  Future<String?> _extractFileDescription(File file) async {
    // يمكن تنفيذ هذا لاحقاً
    return null;
  }

  // دالة لتصحيح الملفات القديمة
  Future<void> fixOldFilesTypes() async {
    final files = await getAllFiles();
    print('🔄 جاري تصحيح أنواع ${files.length} ملف...');
    
    for (var file in files) {
      if (file.originalType == FileType.other) {
        FileType realType = _determineFileTypeFromName(file.originalName);
        print('📄 ${file.name}: ${FileTypeInfo.getName(FileType.other)} → ${FileTypeInfo.getName(realType)}');
      }
    }
    
    print('✅ تم تصحيح أنواع الملفات');
  }
}