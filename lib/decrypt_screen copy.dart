import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import 'app_colors.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  XFile? _encryptedFile;
  File? _decryptedFile;

  String? _fileName;
  bool _isLoading = false;
  bool _showResult = false;
  bool _isSuccess = false;

  final TextEditingController _keyController = TextEditingController();

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildWarningCard(),
                  const SizedBox(height: 25),
                  _buildEncryptedFileCard(),
                  const SizedBox(height: 25),
                  _buildKeyInput(),
                  const SizedBox(height: 25),
                  _buildDecryptButton(),
                  const SizedBox(height: 25),
                  if (_showResult) _buildResultCard(),
                  const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.lock_open, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              'فك تشفير الملفات\nاسترجع ملفاتك الأصلية',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '⚠️ يجب إدخال نفس المفتاح المستخدم أثناء التشفير.',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
      ),
    );
  }

  Widget _buildEncryptedFileCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.insert_drive_file, size: 60),
            const SizedBox(height: 10),
            Text(
              _fileName ?? 'لم يتم اختيار ملف مشفر',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'NotoKufiArabic'),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _pickEncryptedFile,
              icon: const Icon(Icons.folder_open),
              label: const Text(
                'اختر ملف مشفر',
                style: TextStyle(fontFamily: 'NotoKufiArabic'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مفتاح فك التشفير',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoKufiArabic',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _keyController,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'أدخل المفتاح',
            prefixIcon: Icon(Icons.key),
          ),
        ),
      ],
    );
  }

  Widget _buildDecryptButton() {
    final enabled =
        _encryptedFile != null && _keyController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: enabled && !_isLoading ? _decryptFile : null,
        icon: const Icon(Icons.lock_open),
        label: const Text('فك التشفير'),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: _isSuccess
          ? AppColors.success.withOpacity(0.1)
          : AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.error,
              color: _isSuccess ? AppColors.success : AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              _isSuccess ? 'تم فك التشفير بنجاح' : 'فشل فك التشفير',
              style: const TextStyle(
                fontFamily: 'NotoKufiArabic',
                fontSize: 16,
              ),
            ),
            if (_isSuccess) ...[
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _openDecryptedFile,
                icon: const Icon(Icons.open_in_new),
                label: const Text(
                  'فتح الملف',
                  style: TextStyle(fontFamily: 'NotoKufiArabic'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ() {
    return Card(
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '❓ إذا فشل فك التشفير:\n'
          '• المفتاح غير صحيح\n'
          '• الملف ليس من هذا التطبيق\n'
          '• الملف تالف',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ================= LOGIC =================

  Future<void> _pickEncryptedFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(extensions: ['enc']),
      ],
    );

    if (file == null) return;

    setState(() {
      _encryptedFile = file;
      _fileName = file.name;
      _showResult = false;
    });
  }

Future<void> _decryptFile() async {
  setState(() {
    _isLoading = true;
    _showResult = false;
  });

  try {
    final encryptedBytes = await _encryptedFile!.readAsBytes();

    // 🔑 نفس طريقة التشفير القديمة
    final keyText =
        _keyController.text.padRight(32).substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyText);

    // 📦 قراءة طول IV
    final byteData = encryptedBytes.buffer.asByteData();
    final ivLength = byteData.getUint32(0, Endian.little);

    // 🔐 استخراج IV
    final iv = encrypt.IV(
      encryptedBytes.sublist(4, 4 + ivLength),
    );

    // 🔒 البيانات المشفرة
    final encryptedData =
        encryptedBytes.sublist(4 + ivLength);

    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final decryptedBytes = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedData),
      iv: iv,
    );

    final originalName =
        p.basenameWithoutExtension(_encryptedFile!.name);

    final dir = Directory('/storage/emulated/0/Decrypted_files');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final outputFile = File('${dir.path}/$originalName');
    await outputFile.writeAsBytes(decryptedBytes);

    _decryptedFile = outputFile;
    _isSuccess = true;
  } catch (e) {
    _isSuccess = false;
  }

  setState(() {
    _isLoading = false;
    _showResult = true;
  });
}

  Future<void> _openDecryptedFile() async {
    if (_decryptedFile == null) return;
    await OpenFile.open(_decryptedFile!.path);
  }
}
