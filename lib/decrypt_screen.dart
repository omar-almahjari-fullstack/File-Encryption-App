import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_selector/file_selector.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'file_model.dart';
import 'app_colors.dart';

class DecryptScreen extends StatefulWidget {
  final EncryptedFile? initialFile;
  final String? fileName;
  final String? initialFilePath;

  const DecryptScreen({
    super.key,
    this.initialFile,
    this.fileName,
    this.initialFilePath,
  });

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  XFile? _encryptedFile;
  File? _decryptedFile;
  String? _fileName;
  int? _fileSize;
  bool _isLoading = false;
  bool _showResult = false;
  bool _isSuccess = false;
  String? _errorMessage;
  double _decryptionProgress = 0.0;
  String? _originalEncryptedFilePath;

  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialFile();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFile() async {
    try {
      if (widget.initialFile != null) {
        final file = File(widget.initialFile!.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setState(() {
            _encryptedFile = XFile(
              file.path,
              name: widget.initialFile!.name,
              bytes: bytes,
            );
            _fileName = widget.initialFile!.name;
            _fileSize = bytes.length;
            _originalEncryptedFilePath = file.path;
          });
          _showMessage('تم تحديد الملف تلقائياً: ${widget.initialFile!.name}', AppColors.success);
          return;
        }
      }

      if (widget.initialFilePath != null) {
        final file = File(widget.initialFilePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final name = widget.fileName ?? file.path.split('/').last;
          setState(() {
            _encryptedFile = XFile(widget.initialFilePath!, name: name, bytes: bytes);
            _fileName = name;
            _fileSize = bytes.length;
            _originalEncryptedFilePath = file.path;
          });
          _showMessage('تم تحديد الملف تلقائياً: $name', AppColors.success);
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل الملف: $e');
    }
  }

  Future<void> _deleteEncryptedFile() async {
    if (_originalEncryptedFilePath == null) return;

    try {
      final encryptedFile = File(_originalEncryptedFilePath!);
      if (await encryptedFile.exists()) {
        await encryptedFile.delete();
        print('🗑️ تم حذف الملف المشفر: ${encryptedFile.path}');
      }
    } catch (e) {
      print('❌ خطأ في حذف الملف المشفر: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فك تشفير الملفات'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildEncryptedFileCard(),
                  const SizedBox(height: 20),
                  _buildKeyInput(),
                  const SizedBox(height: 20),
                  _buildDecryptButton(),
                  const SizedBox(height: 20),
                  if (_showResult) _buildResultCard(),
                  const SizedBox(height: 16),
                  _buildFAQ(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فك تشفير الملفات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'فك تشفير الملفات المشفرة بواسطة التطبيق',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildEncryptedFileCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.file_present, size: 55, color: AppColors.primary),
              const SizedBox(height: 12),
              
              if (_encryptedFile != null) ...[
                Column(
                  children: [
                    Text(
                      _fileName!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ENCRYPTED',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatFileSize(_fileSize ?? 0),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickEncryptedFile,
                          icon: const Icon(Icons.change_circle_rounded, size: 16),
                          label: const Text('تغيير الملف'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _clearFile,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('إزالة'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  children: [
                    Text(
                      'لم يتم اختيار ملف',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر ملف مشفر (.enc) لفك تشفيره',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickEncryptedFile,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('تصفح الملفات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildKeyInput() {
    final bool isValid = _isKeyValid();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مفتاح فك التشفير',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        TextField(
          controller: _keyController,
          obscureText: true,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'أدخل مفتاح التشفير المستخدم سابقاً',
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        
        const SizedBox(height: 8),
        Text(
          '⚠️ يجب إدخال نفس المفتاح الذي استخدم للتشفير',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.warning,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDecryptButton() {
    bool isEnabled = _encryptedFile != null && 
                     _keyController.text.isNotEmpty &&
                     !_isLoading;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? _decryptFile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.accent : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('جاري فك التشفير...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, size: 20),
                  SizedBox(width: 8),
                  Text('فك تشفير الملف', style: TextStyle(fontSize: 15)),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: _isSuccess ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _isSuccess ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isSuccess ? Icons.check_circle : Icons.error,
                  color: _isSuccess ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSuccess ? 'نجاح!' : 'فشل!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _isSuccess ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        _isSuccess 
                          ? 'تم فك تشفير الملف بنجاح'
                          : _errorMessage ?? 'فشل فك تشفير الملف',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSuccess && _decryptedFile != null) ...[
              const SizedBox(height: 10),
              Divider(color: AppColors.success.withOpacity(0.1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم حفظ الملف في مجلد Decrypted_files',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تم حذف الملف المشفر الأصلي تلقائياً',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openDecryptedFile,
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('فتح الملف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _buildFAQ() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('تعليمات فك التشفير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('يجب أن يكون الملف بتنسيق .enc (منتج من هذا التطبيق)', Icons.file_copy),
          _buildTip('استخدم نفس مفتاح التشفير الذي استخدمه صديقك', Icons.vpn_key),
          _buildTip('الملف المفكوك سيحفظ في مجلد Decrypted_files', Icons.folder),
          _buildTip('سيتم حذف الملف المشفر الأصلي تلقائياً بعد النجاح', Icons.delete_forever),
          _buildTip('يمكنك مشاركة الملف المفكوك مع أي تطبيق', Icons.share),
        ],
      ),
    );
  }

  Widget _buildTip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 180,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: _decryptionProgress,
                      strokeWidth: 4,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  Icon(Icons.lock_open, color: AppColors.primary, size: 26),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'جاري فك التشفير...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_decryptionProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _decryptionProgress,
                backgroundColor: AppColors.secondary,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEncryptedFile() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(extensions: ['enc'], label: 'الملفات المشفرة'),
        ],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      
      setState(() {
        _encryptedFile = file;
        _fileName = file.name;
        _fileSize = bytes.length;
        _originalEncryptedFilePath = file.path;
        _showResult = false;
        _isSuccess = false;
        _errorMessage = null;
      });
      
      _showMessage('تم تحميل الملف المشفر: ${file.name}', AppColors.success);
    } catch (e) {
      _showMessage('خطأ في اختيار الملف: $e', AppColors.error);
    }
  }

  Future<void> _decryptFile() async {
    if (_encryptedFile == null) {
      _showMessage('الرجاء اختيار ملف أولاً', AppColors.warning);
      return;
    }
    
    if (_keyController.text.isEmpty) {
      _showMessage('الرجاء إدخال مفتاح فك التشفير', AppColors.error);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _decryptionProgress = 0.0;
      _showResult = false;
      _errorMessage = null;
    });

    try {
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        setState(() {
          _decryptionProgress = i / 100;
        });
      }
      
      final encryptedBytes = await _encryptedFile!.readAsBytes();
      
      print('🔍 بدء عملية فك التشفير...');
      print('📄 اسم الملف: $_fileName');
      print('📊 حجم الملف: ${encryptedBytes.length} بايت');
      
      final keyText = _keyController.text;
      final paddedKey = keyText.padRight(32).substring(0, 32);
      final key = encrypt.Key.fromUtf8(paddedKey);
      
      if (encryptedBytes.length < 20) {
        throw Exception('الملف صغير جداً أو تالف');
      }
      
      final ivLength = _bytesToInt32(encryptedBytes.sublist(0, 4));
      print('📐 طول IV المخزن: $ivLength بايت');
      
      if (ivLength != 16) {
        throw Exception('تنسيق ملف غير صالح: طول IV غير صحيح ($ivLength)');
      }
      
      if (4 + ivLength > encryptedBytes.length) {
        throw Exception('الملف تالف: بيانات IV غير كاملة');
      }
      
      final iv = encrypt.IV(encryptedBytes.sublist(4, 4 + ivLength));
      final encryptedData = encryptedBytes.sublist(4 + ivLength);
      
      if (encryptedData.isEmpty) {
        throw Exception('ملف تالف: لا توجد بيانات مشفرة');
      }
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decryptedBytes = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedData),
        iv: iv,
      );
      
      print('🎉 تم فك التشفير بنجاح!');
      
      String fileNameWithoutEnc = _encryptedFile!.name;
      if (fileNameWithoutEnc.toLowerCase().endsWith('.enc')) {
        fileNameWithoutEnc = fileNameWithoutEnc.substring(0, fileNameWithoutEnc.length - 4);
      }
      
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح صلاحية التخزين');
      }
      
      final dir = Directory('/storage/emulated/0/Decrypted_files');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      String finalName = fileNameWithoutEnc;
      int counter = 1;
      
      while (await File('${dir.path}/$finalName').exists()) {
        final parts = fileNameWithoutEnc.split('.');
        String nameWithoutExt = parts.length > 1 
            ? fileNameWithoutEnc.substring(0, fileNameWithoutEnc.lastIndexOf('.'))
            : fileNameWithoutEnc;
        String extension = parts.length > 1 ? parts.last : '';
        finalName = '${nameWithoutExt}_(${counter++}).${extension.isNotEmpty ? extension : ""}';
      }
      
      final outputPath = '${dir.path}/$finalName';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(decryptedBytes);
      
      print('💾 تم حفظ الملف في: $outputPath');
      
      // حذف الملف المشفر الأصلي بعد نجاح العملية
      await _deleteEncryptedFile();
      
      _decryptedFile = outputFile;
      
      setState(() {
        _decryptionProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() {
        _isLoading = false;
        _showResult = true;
        _isSuccess = true;
      });
      
      _showMessage('✅ تم فك التشفير وحذف الملف المشفر بنجاح!', AppColors.success);
      
    } catch (e, stackTrace) {
      print('❌ خطأ في فك التشفير: $e');
      print('📋 StackTrace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _showResult = true;
        _isSuccess = false;
      });
      
      String errorMsg;
      
      if (e.toString().contains('Invalid key length')) {
        errorMsg = 'خطأ في طول المفتاح';
      } else if (e.toString().contains('Invalid or corrupted pad block') ||
                 e.toString().contains('Bad state') ||
                 e.toString().contains('Invalid padding')) {
        errorMsg = 'مفتاح فك التشفير غير صحيح';
      } else if (e.toString().contains('Bad state') || 
                 e.toString().contains('RangeError') ||
                 e.toString().contains('index out of range')) {
        errorMsg = 'الملف تالف أو غير مكتمل';
      } else if (e.toString().contains('Invalid IV')) {
        errorMsg = 'بيانات التهيئة في الملف تالفة';
      } else if (e.toString().contains('storage')) {
        errorMsg = 'خطأ في صلاحيات التخزين';
      } else {
        errorMsg = 'فشل فك التشفير: ${e.toString()}';
      }
      
      _errorMessage = errorMsg;
      _showMessage('❌ $errorMsg', AppColors.error);
    }
  }

  int _bytesToInt32(List<int> bytes) {
    if (bytes.length < 4) return 0;
    return (bytes[0] & 0xFF) |
           ((bytes[1] & 0xFF) << 8) |
           ((bytes[2] & 0xFF) << 16) |
           ((bytes[3] & 0xFF) << 24);
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) return true;
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _openDecryptedFile() async {
    if (_decryptedFile == null) return;
    try {
      await OpenFile.open(_decryptedFile!.path);
    } catch (e) {
      _showMessage('لا يمكن فتح الملف: $e', AppColors.error);
    }
  }

  void _clearFile() {
    setState(() {
      _encryptedFile = null;
      _fileName = null;
      _fileSize = null;
      _decryptedFile = null;
      _originalEncryptedFilePath = null;
      _showResult = false;
      _isSuccess = false;
      _errorMessage = null;
      _keyController.clear();
    });
  }

  bool _isKeyValid() {
    return _keyController.text.isNotEmpty;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} جيجابايت';
  }
}