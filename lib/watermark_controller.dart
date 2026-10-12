import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للوصول إلى الـ assets

class WatermarkController {
  // تحميل العلامة المائية من الـ assets
  static Future<Image> loadWatermarkImage() async {
    try {
      return Image.asset(
        'assets/images/watermark_logo.png',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
      );
    } catch (e) {
      // إذا لم توجد الصورة، استخدم نص بديل
      print('❌ لم يتم العثور على صورة العلامة المائية: $e');
      // Return a transparent 1x1 image as a fallback
      return Image.memory(
        Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82
        ]),
        width: 100,
        height: 100,
        fit: BoxFit.contain,
      );
    }
  }

  // علامة مائية افتراضية (نصية) كبديل
  static Widget _getDefaultWatermark() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              color: Colors.white,
              size: 30,
            ),
            Text(
              'مشفّر',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الحصول على صورة العلامة المائية كـ bytes (للتشفير مع الملف)
  static Future<Uint8List> getWatermarkBytes() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/watermark_logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print('❌ خطأ في تحميل صورة العلامة المائية: $e');
      return Uint8List(0);
    }
  }

  // التحقق من وجود العلامة المائية في الـ assets
  static Future<bool> checkWatermarkExists() async {
    try {
      await rootBundle.load('assets/images/watermark_logo.png');
      return true;
    } catch (e) {
      return false;
    }
  }
}