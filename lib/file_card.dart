import 'package:flutter/material.dart';
import 'file_model.dart';

class FileCard extends StatelessWidget {
  final EncryptedFile file;
  final VoidCallback onTap;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة الملف حسب النوع الأصلي
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: FileTypeInfo.getColor(file.originalType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    FileTypeInfo.getIcon(file.originalType),
                    size: 40,
                    color: FileTypeInfo.getColor(file.originalType),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // اسم الملف الأصلي
              Text(
                _truncateFileName(file.originalName, 20),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 5),
              
              // نوع الملف وموعد التشفير
              Row(
                children: [
                  // بطاقة نوع الملف
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FileTypeInfo.getColor(file.originalType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      FileTypeInfo.getName(file.originalType),
                      style: TextStyle(
                        fontSize: 10,
                        color: FileTypeInfo.getColor(file.originalType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // الحجم والتاريخ
                  Expanded(
                    child: Text(
                      '${_formatSize(file.size)} • ${_formatDate(file.encryptionDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateFileName(String fileName, int maxLength) {
    if (fileName.length <= maxLength) return fileName;
    return '${fileName.substring(0, maxLength)}...';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} جيجابايت';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}