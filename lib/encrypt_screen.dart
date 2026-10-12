import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:share_plus/share_plus.dart';

import 'app_colors.dart';
import 'package:permission_handler/permission_handler.dart';

// هذه الدالة ترجع بيانات الملف كـ Uint8List
Future<Uint8List?> pickFile() async {
  try {
    final typeGroup = XTypeGroup(
      label: 'any',
      extensions: ['*'], // كل أنواع الملفات
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null; // المستخدم ألغى الاختيار

    return await file.readAsBytes(); // ترجع البيانات كـ Uint8List
  } catch (e) {
    print('فشل اختيار الملف: $e');
    return null;
  }
}





Future<bool> _requestStoragePermission() async {
  if (await Permission.storage.isGranted) {
    return true;
  }

  final status = await Permission.storage.request();
  return status.isGranted;
}


class EncryptScreen extends StatefulWidget {
  const EncryptScreen({super.key});

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  // متغيرات الملف
  XFile? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _fileExtension;
  Uint8List? _fileBytes;  // بيانات الملف
  
  bool _isLoading = false;
  bool _showResult = false;
  bool _isSuccess = true;
  double _encryptionProgress = 0.0;
  String? _savedFilePath;
  
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تشفير الملفات'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildFileCard(),
                  const SizedBox(height: 25),
                  _buildKeyInput(),
                  const SizedBox(height: 25),
                  _buildEncryptButton(),
                  const SizedBox(height: 25),
                  if (_showResult) _buildResultCard(),
                  const SizedBox(height: 20),
                  _buildSecurityTips(),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تشفير الملفات',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'حمي ملفاتك بتشفير AES-256 عالي الأمان',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.insert_drive_file, size: 60, color: AppColors.primary),
              const SizedBox(height: 15),
              
              if (_selectedFile != null) ...[
                Column(
                  children: [
                    Text(
                      _fileName!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // حجم ونوع الملف
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _fileExtension?.toUpperCase() ?? 'FILE',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatFileSize(_fileSize ?? 0),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // أزرار التحكم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickFileWithSelector,
                          icon: const Icon(Icons.change_circle_rounded, size: 18),
                          label: const Text('تغيير الملف'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _clearFile,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('إزالة'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    
                    // حالة التحميل
                    if (_fileBytes != null) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'تم تحميل الملف (${_formatFileSize(_fileBytes!.length)})',
                              style: TextStyle(color: AppColors.success, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                // عندما لا يوجد ملف مختار
                Column(
                  children: [
                    Text(
                      'لم يتم اختيار ملف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر أي ملف من جهازك للتشفير',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickFileWithSelector,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('تصفح الملفات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFileWithSelector() async {
    try {
      const maxFileSize = 100 * 1024 * 1024; // 100MB كحد أقصى
      
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(
            label: 'الجميع',
            mimeTypes: ['*/*'],
          ),
          const XTypeGroup(
            label: 'الصور',
            mimeTypes: ['image/*'],
            extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
          ),
          const XTypeGroup(
            label: 'المستندات',
            mimeTypes: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            extensions: ['pdf', 'doc', 'docx'],
          ),
          const XTypeGroup(
            label: 'النصوص',
            mimeTypes: ['text/plain'],
            extensions: ['txt'],
          ),
          const XTypeGroup(
            label: 'الأرشيفات',
            extensions: ['zip', 'rar', '7z'],
          ),
        ],
      );

      if (file != null) {
        final size = await file.length();
        
        if (size > maxFileSize) {
          _showMessage('حجم الملف كبير جداً (${_formatFileSize(size)})', AppColors.error);
          return;
        }

        setState(() => _isLoading = true);
        
        final bytes = await file.readAsBytes();
        
        setState(() {
          _selectedFile = file;
          _fileName = file.name;
          _fileSize = size;
          _fileExtension = _getFileExtension(file.name);
          _fileBytes = bytes;
          _showResult = false;
          _savedFilePath = null;
          _isLoading = false;
        });
        
        _showMessage('تم تحميل الملف: ${file.name}', AppColors.success);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('خطأ في اختيار الملف: $e');
      _showMessage('خطأ في اختيار الملف: ${e.toString()}', AppColors.error);
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'غير معروف';
  }

  Future<void> _performEncryption() async {
    if (_selectedFile == null || _fileBytes == null) {
      _showMessage('الرجاء اختيار ملف أولاً', AppColors.warning);
      return;
    }
    
    if (!_isKeyValid()) {
      _showMessage('المفتاح يجب أن يحتوي على 8 أحرف على الأقل', AppColors.error);
      return;
    }
    
    if (_keyController.text != _confirmController.text) {
      _showMessage('المفتاحان غير متطابقين', AppColors.error);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _encryptionProgress = 0.0;
      _showResult = false;
      _savedFilePath = null;
    });

    try {
      // محاكاة تقدم العملية
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        setState(() {
          _encryptionProgress = i / 100;
        });
      }
      
      // التشفير الفعلي
      final encryptedData = await _encryptFile();
      
      // حفظ الملف المشفر
      await _saveEncryptedFile(encryptedData);
      
      setState(() {
        _encryptionProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showResult = true;
        _isSuccess = false;
      });
      
      _showMessage('فشل التشفير: ${e.toString()}', AppColors.error);
    }
  }

  // Future<Uint8List> _encryptFile() async {
  //   try {
  //     final key = _keyController.text;
      
  //     // إنشاء مفتاح 256 بت (32 بايت) من المفتاح المدخل
  //     final paddedKey = key.padRight(32).substring(0, 32);
  //     final encryptionKey = encrypt.Key.fromUtf8(paddedKey);
      
  //     // إنشاء متجه تهيئة (IV) عشوائي
  //     final iv = encrypt.IV.fromSecureRandom(16);
      
  //     // إنشاء كائن التشفير باستخدام AES في وضع CBC
  //     final encrypter = encrypt.Encrypter(encrypt.AES(encryptionKey, mode: encrypt.AESMode.cbc));
      
  //     // تشفير البيانات
  //     final encrypted = encrypter.encryptBytes(_fileBytes!, iv: iv);
      
  //     // حفظ البيانات المشفرة مع الـ IV في بداية الملف
  //     // التنسيق: [4 بايت لطول IV] + [IV] + [البيانات المشفرة]
  //     final ivBytes = iv.bytes;
  //     final ivLength = ivBytes.length;
  //     final ivLengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, ivLength, Endian.little);
      
  //     final result = Uint8List.fromList([
  //       ...ivLengthBytes,
  //       ...ivBytes,
  //       ...encrypted.bytes
  //     ]);
      
  //     return result;
  //   } catch (e) {
  //     print('خطأ في التشفير: $e');
  //     throw Exception('فشل التشفير: ${e.toString()}');
  //   }
  // }



Future<Uint8List> _encryptFile() async {
  if (_fileBytes == null) {
    throw Exception('لم يتم اختيار أي ملف');
  }

  try {
    final key = _keyController.text;

    // إنشاء مفتاح 256 بت (32 بايت) من المفتاح المدخل
    final paddedKey = key.padRight(32).substring(0, 32);
    final encryptionKey = encrypt.Key.fromUtf8(paddedKey);

    // إنشاء متجه تهيئة (IV) عشوائي
    final iv = encrypt.IV.fromSecureRandom(16);

    // كائن التشفير باستخدام AES CBC
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encryptionKey, mode: encrypt.AESMode.cbc),
    );

    // تشفير بيانات الملف
    final encrypted = encrypter.encryptBytes(_fileBytes!, iv: iv);

    // حفظ الـ IV مع البيانات المشفرة
    final ivBytes = iv.bytes;
    final ivLengthBytes =
        Uint8List(4)..buffer.asByteData().setUint32(0, ivBytes.length, Endian.little);

    return Uint8List.fromList([
      ...ivLengthBytes,
      ...ivBytes,
      ...encrypted.bytes,
    ]);
  } catch (e) {
    print('خطأ في التشفير: $e');
    throw Exception('فشل التشفير: ${e.toString()}');
  }
}




  // Future<void> _saveEncryptedFile(Uint8List encryptedData) async {
  //   try {
  //     final originalName = _fileName!.split('.').first;
  //     final String? savePath = await getSavePath(
  //       suggestedName: '${originalName}_مشفر.enc',
  //     );

  //     if (savePath != null && mounted) {
  //       final file = XFile.fromData(
  //         encryptedData,
  //         mimeType: 'application/octet-stream',
  //         name: savePath.split('/').last,
  //       );
        
  //       await file.saveTo(savePath);
        
  //       setState(() {
  //         _isLoading = false;
  //         _showResult = true;
  //         _isSuccess = true;
  //         _savedFilePath = savePath;
  //       });
        
  //       _showMessage('تم حفظ الملف المشفر بنجاح!', AppColors.success);
        
  //       // عرض خيارات للمستخدم
  //       _showSaveSuccessDialog(savePath);
  //     } else if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //     throw Exception('فشل حفظ الملف: ${e.toString()}');
  //   }
  // }
/*************  ✨ Windsurf Command ⭐  *************/
  /// يحفظ الملف المشفر في الموقع المحدد
  ///
  /// [encryptedData] بيانات المشفرة
  ///
  /// throws Exception if there is an error saving the file
  ///
  /// Example:
  ///
  /// final encryptedData = ...;
  /// await _saveEncryptedFile(encryptedData);


Future<void> _saveEncryptedFile(Uint8List encryptedData) async {
  try {
    // 1. طلب الإذن
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showMessage('❌ لم يتم منح صلاحية التخزين', AppColors.error);
      return;
    }

    // 2. اسم الملف (يحافظ على الامتداد الأصلي + .enc)
    final fileName = '${_fileName!}.enc';

    // 3. مسار التخزين الداخلي + اسم المجلد
    final Directory targetDir =
        Directory('/storage/emulated/0/Encrypted_files');

    // 4. إنشاء المجلد إذا لم يكن موجودًا
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 5. إنشاء الملف
    final File file = File('${targetDir.path}/$fileName');

    // 6. حفظ البيانات
    await file.writeAsBytes(encryptedData);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _showResult = true;
      _isSuccess = true;
      _savedFilePath = file.path;
    });

    _showMessage(
      '✅ تم حفظ الملف داخل Encrypted_files',
      AppColors.success,
    );

    _showSaveSuccessDialog(file.path);

  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _showResult = true;
      _isSuccess = false;
    });

    _showMessage('❌ فشل الحفظ: $e', AppColors.error);
  }
}


// دالة تعطي خيارين حقيقيين فقط
void _showRealOptions(String filePath, String fileName, int fileSize) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_download, color: AppColors.primary),
          SizedBox(width: 8),
          Text('الملف جاهز'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تأكيد حقيقي
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ تم تشفير الملف بنجاح', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('الحجم: ${_formatFileSize(fileSize)}',
                           style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // الخيار 1: مشاركة مباشرة
          _buildOptionCard(
            icon: Icons.share,
            title: 'مشاركة الملف الآن',
            description: 'شارك الملف مع أي تطبيق (واتساب، بريد، تخزين سحابي)',
            color: AppColors.accent,
            onTap: () {
              Navigator.pop(context);
              _shareFileDirectly(filePath);
            },
          ),
          
          SizedBox(height: 15),
          
          // الخيار 2: حفظ في التحميلات
          _buildOptionCard(
            icon: Icons.save_alt,
            title: 'حفظ في التحميلات',
            description: 'يحفظ الملف في مجلد التنزيلات على جهازك',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              _saveToDownloads(filePath, fileName);
            },
          ),
          
          SizedBox(height: 15),
          
          // معلومات تقنية للمطور
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔧 معلومات تقنية:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                SelectableText(
                  'المسار المؤقت: ${filePath.substring(0, min(50, filePath.length))}...',
                  style: TextStyle(fontSize: 9, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'),
        ),
      ],
    ),
  );
}

// دالة المشاركة المباشرة
Future<void> _shareFileDirectly(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      // هذه المشاركة الحقيقية التي تتيح لك حفظ الملف
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'ملف مشفر - ${filePath.split('/').last}',
        subject: 'ملف مشفر',
      );
    } else {
      _showMessage('الملف غير موجود!', AppColors.error);
    }
  } catch (e) {
    _showMessage('خطأ في المشاركة: $e', AppColors.error);
  }
}

// دالة حفظ في التحميلات
Future<void> _saveToDownloads(String tempFilePath, String fileName) async {
  try {
    // اقرأ الملف من الموقع المؤقت
    final tempFile = File(tempFilePath);
    final fileData = await tempFile.readAsBytes();
    
    // احفظ في التحميلات
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      final savePath = '${downloadsDir.path}/$fileName';
      final File savedFile = File(savePath);
      await savedFile.writeAsBytes(fileData);
      
      _showMessage('✅ تم حفظ الملف في: التحميلات/$fileName', AppColors.success);
      
      // شارك الملف المحفوظ
      await Share.shareXFiles([XFile(savePath)]);
    } else {
      // إذا لم يعمل مجلد التحميلات، شارك من الموقع المؤقت
      await _shareFileDirectly(tempFilePath);
    }
  } catch (e) {
    _showMessage('حاول المشاركة مباشرة', AppColors.warning);
    await _shareFileDirectly(tempFilePath);
  }
}

// دالة لبناء بطاقة خيار
Widget _buildOptionCard({
  required IconData icon,
  required String title,
  required String description,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color),
        ],
      ),
    ),
  );
}
  // void _showSaveSuccessDialog(String filePath) {
  //   final fileName = filePath.split('/').last;
    
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Row(
  //         children: [
  //           Icon(Icons.check_circle, color: AppColors.success),
  //           SizedBox(width: 8),
  //           Text('تم التشفير بنجاح'),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('تم حفظ الملف: $fileName', style: TextStyle(fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 10),
  //           Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: Colors.grey[100],
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text('مسار الملف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   filePath,
  //                   style: const TextStyle(fontSize: 11, color: Colors.grey),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 15),
  //           const Text(
  //             '⚠️ مهم: احفظ مفتاح التشفير في مكان آمن، لأنك ستحتاجه لفك التشفير',
  //             style: TextStyle(fontSize: 12, color: Colors.orange),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('حسناً'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _clearFile();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.primary,
  //             foregroundColor: Colors.white,
  //           ),
  //           child: const Text('تشفير ملف جديد'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

 void _showSaveSuccessDialog(String filePath) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('✅ تم الحفظ بنجاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم حفظ الملف المشفّر داخل مجلد:',
            ),
            const SizedBox(height: 8),
            const Text(
              'Encrypted_files',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              filePath,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          // 🔹 زر المشاركة
          TextButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('مشاركة الملف'),
            onPressed: () async {
              Navigator.pop(context);

              await Share.shareXFiles(
                [XFile(filePath)],
                text: '📁 ملف مشفّر',
              );
            },
          ),

          // 🔹 زر الإغلاق
          TextButton(
            child: const Text('إغلاق'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

 
 
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} جيجابايت';
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileExtension = null;
      _fileBytes = null;
      _showResult = false;
      _savedFilePath = null;
      _keyController.clear();
      _confirmController.clear();
    });
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildKeyInput() {
    final bool isValid = _isKeyValid();
    final bool doKeysMatch = _keyController.text == _confirmController.text;
    final bool showMatchError = _confirmController.text.isNotEmpty && !doKeysMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مفتاح التشفير',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_keyController.text.isNotEmpty)
              IconButton(
                onPressed: _generateRandomKey,
                icon: const Icon(Icons.autorenew),
                tooltip: 'توليد مفتاح عشوائي',
                color: AppColors.primary,
              ),
          ],
        ),
        const SizedBox(height: 10),
        
        TextField(
          controller: _keyController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'أدخل مفتاح التشفير (8 أحرف على الأقل)',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: Icon(
              _keyController.text.isEmpty 
                ? null 
                : isValid 
                  ? Icons.check_circle 
                  : Icons.error,
              color: _keyController.text.isEmpty 
                ? null 
                : isValid 
                  ? AppColors.success 
                  : AppColors.error,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) => setState(() {}),
        ),
        
        if (_keyController.text.isNotEmpty && !isValid)
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Text(
              'المفتاح يجب أن يحتوي على 8 أحرف على الأقل',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        
        const SizedBox(height: 15),
        
        TextField(
          controller: _confirmController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'تأكيد مفتاح التشفير',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: Icon(
              _confirmController.text.isEmpty 
                ? null 
                : doKeysMatch 
                  ? Icons.check_circle 
                  : Icons.error,
              color: _confirmController.text.isEmpty 
                ? null 
                : doKeysMatch 
                  ? AppColors.success 
                  : AppColors.error,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) => setState(() {}),
        ),
        
        if (showMatchError)
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Text(
              'المفتاحان غير متطابقين',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        
        const SizedBox(height: 10),
        if (_keyController.text.isNotEmpty) _buildKeyStrength(),
      ],
    );
  }

  void _generateRandomKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    final key = String.fromCharCodes(
      List.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    
    _keyController.text = key;
    _confirmController.text = key;
    setState(() {});
    
    _showMessage('تم توليد مفتاح عشوائي قوي', AppColors.success);
  }

  bool _isKeyValid() {
    return _keyController.text.length >= 8;
  }

  Widget _buildKeyStrength() {
    int strength = _calculateKeyStrength(_keyController.text);
    Color color = AppColors.error;
    String text = 'ضعيف';
    double value = strength / 5;
    
    if (strength >= 4) {
      color = AppColors.success;
      text = 'قوي جداً';
    } else if (strength >= 3) {
      color = AppColors.success.withOpacity(0.8);
      text = 'قوي';
    } else if (strength >= 2) {
      color = AppColors.warning;
      text = 'متوسط';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('قوة المفتاح:'),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.secondary,
          color: color,
          borderRadius: BorderRadius.circular(5),
          minHeight: 8,
        ),
        const SizedBox(height: 5),
        Text(
          _getKeyStrengthTips(strength),
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getKeyStrengthTips(int strength) {
    if (strength < 2) return 'أضف أحرف كبيرة وصغيرة وأرقام ورموز';
    if (strength < 3) return 'جيد، يمكنك إضافة رموز لزيادة القوة';
    if (strength < 4) return 'ممتاز، المفتاح قوي';
    return 'ممتاز! المفتاح قوي جداً وآمن';
  }

  Widget _buildEncryptButton() {
    bool isEnabled = _selectedFile != null && 
                     _isKeyValid() &&
                     _keyController.text == _confirmController.text;
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isEnabled && !_isLoading ? _performEncryption : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.accent : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('جاري التشفير...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 10),
                  Text('تشفير الملف', style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: _isSuccess ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isSuccess ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isSuccess ? Icons.check_circle : Icons.error,
                  color: _isSuccess ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSuccess ? 'نجاح!' : 'فشل!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isSuccess ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        _isSuccess 
                          ? 'تم تشفير الملف بنجاح باستخدام AES-256'
                          : 'فشل تشفير الملف',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSuccess && _savedFilePath != null) ...[
              const SizedBox(height: 12),
              Divider(color: AppColors.success.withOpacity(0.2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم حفظ الملف: ${_savedFilePath!.split('/').last}',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text('نصائح أمنية', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          _buildTip('يستخدم التطبيق AES-256 CBC مع IV عشوائي', Icons.lock),
          _buildTip('احفظ المفتاح في مكان آمن (مثل مدير كلمات المرور)', Icons.vpn_key),
          _buildTip('لا تشارك المفتاح مع أي شخص', Icons.person_off),
          _buildTip('احتفظ بنسخة من الملف الأصلي قبل التشفير', Icons.backup),
          _buildTip('استخدم مفتاحاً مختلفاً لكل ملف مهم', Icons.key_off),
        ],
      ),
    );
  }

  Widget _buildTip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 200,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: _encryptionProgress,
                      strokeWidth: 5,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  Icon(Icons.lock, color: AppColors.primary, size: 30),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'جاري التشفير...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_encryptionProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _encryptionProgress,
                backgroundColor: AppColors.secondary,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateKeyStrength(String key) {
    int strength = 0;
    if (key.length >= 8) strength++;
    if (key.length >= 12) strength++;
    if (key.contains(RegExp(r'[A-Z]'))) strength++;
    if (key.contains(RegExp(r'[a-z]'))) strength++;
    if (key.contains(RegExp(r'\d'))) strength++;
    if (key.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;
    return strength.clamp(0, 5); // الحد الأقصى 5 نقاط
  }
}