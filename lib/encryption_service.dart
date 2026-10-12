import 'package:encrypt/encrypt.dart';
import 'dart:io';

class EncryptionService {
  static Future<File> encryptFile(File inputFile, String key) async {
    final plainText = await inputFile.readAsBytes();
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(Key.fromUtf8(key.padRight(32))));
    
    final encrypted = encrypter.encryptBytes(plainText, iv: iv);
    
    // حفظ الملف المشفر
    final encryptedFile = File('${inputFile.path}.encrypted');
    await encryptedFile.writeAsBytes(encrypted.bytes);
    
    return encryptedFile;
  }
}