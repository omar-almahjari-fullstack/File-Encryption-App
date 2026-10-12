import 'package:flutter/material.dart';

class AppColors {
  // ألوان التطبيق
  static const Color primary = Color(0xFF2196F3);      // أزرق
  static const Color primaryDark = Color(0xFF1976D2);  // أزرق داكن
  static const Color secondary = Color(0xFFF5F5F5);    // رمادي فاتح
  static const Color accent = Color(0xFF1A237E);       // أزرق نيلي
  
  // ألوان الحالة
  static const Color success = Color(0xFF4CAF50);      // أخضر
  static const Color error = Color(0xFFF44336);        // أحمر
  static const Color warning = Color(0xFFFF9800);      // برتقالي
  
  // ألوان الواجهة
  static const Color background = Color(0xFFFAFAFA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color info = Color(0xFF2196F3);  // أضف هذا السطر 👈

}

// النصوص العربية
class AppStrings {
  // شاشة البصمة
  static const String biometricTitle = 'تطبيق التشفير الآمن';
  static const String biometricSubtitle = 'التطبيق محمي ببصمة الجهاز';
  static const String biometricButton = '🔐 فتح بالتأكيد';
  static const String biometricHint = 'استخدم بصمة إصبعك لفتح التطبيق';
  static const String biometricError = 'فشل المصادقة. حاول مرة أخرى.';
  
  // التنقل
  static const String encryptTab = 'تشفير';
  static const String decryptTab = 'فك التشفير';
  static const String appTitle = 'تشفير الملفات';
  
  // أزرار
  static const String selectFile = 'اختر ملف';
  static const String encryptButton = 'تشفير الملف';
  static const String decryptButton = 'فك تشفير الملف';
  static const String browseFiles = 'تصفح الملفات';
  static const String changeFile = 'تغيير';
  static const String removeFile = 'إزالة';
  
  // حقول الإدخال
  static const String enterKey = 'أدخل مفتاح التشفير';
  static const String confirmKey = 'تأكيد المفتاح';
  static const String keyHint = 'أدخل 8 أحرف على الأقل';
  static const String requiredKey = 'مطلوب';
  
  // رسائل
  static const String fileSelected = 'تم اختيار الملف:';
  static const String noFile = 'لم يتم اختيار ملف';
  static const String encrypting = 'جاري التشفير...';
  static const String decrypting = 'جاري فك التشفير...';
  static const String pleaseWait = 'يرجى الانتظار';
  static const String success = 'نجاح!';
  static const String failed = 'فشل!';
  
  // النتائج
  static const String encryptSuccess = 'تم تشفير الملف بنجاح!';
  static const String encryptFailed = 'فشل التشفير. تحقق من المفتاح.';
  static const String decryptSuccess = 'تم فك تشفير الملف بنجاح!';
  static const String decryptFailed = 'فشل فك التشفير. المفتاح خاطئ؟';
  
  // النصائح
  static const String keyTip = 'احفظ هذا المفتاح! ستحتاجه لفك التشفير.';
  static const String securityTip = 'استخدم كلمات مرور قوية وفريدة لكل ملف';
  static const String warning = 'تحذير هام';
  static const String warningMessage = 'المفاتيح المفقودة لا يمكن استرجاعها';
  
  // الإحصائيات
  static const String encryption = 'تشفير';
  static const String offline = 'دون اتصال';
  static const String fast = 'سريع';
}