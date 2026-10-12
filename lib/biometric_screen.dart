import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'app_colors.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Random _random = Random();
  bool _isAuthenticating = false;
  List<FallingDigit> _fallingDigits = [];
  Timer? _digitTimer;

  @override
  void initState() {
    super.initState();
    _startFallingDigits();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _digitTimer?.cancel();
    super.dispose();
  }

  void _startFallingDigits() {
    _digitTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          // إضافة أرقام عشوائية أقل تواتراً لحفظ الأداء
          for (int i = 0; i < _random.nextInt(2) + 1; i++) {
            _fallingDigits.add(FallingDigit(
              digit: _random.nextInt(10).toString(),
              left: _random.nextDouble() * 100,
              speed: _random.nextDouble() * 2 + 0.5,
              size: _random.nextDouble() * 20 + 15,
              opacity: _random.nextDouble() * 0.3 + 0.1,
            ));
          }
          
          // تحريك الأرقام الحالية وإزالة التي تجاوزت الشاشة
          _fallingDigits = _fallingDigits
            .map((digit) => digit.copyWith(top: digit.top + digit.speed))
            .where((digit) => digit.top < 120) // زيادة الحد لتغطية كامل الشاشة
            .toList();
        });
      }
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        Future.delayed(const Duration(seconds: 2), _navigateToHome);
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 2), _navigateToHome);
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'المصادقة بالبصمة مطلوبة للوصول إلى تطبيق تشفير الملفات',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _onSuccess();
      } else {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onSuccess() {
    // زيادة سرعة الأرقام عند النجاح
    setState(() {
      _fallingDigits = _fallingDigits.map((digit) => digit.copyWith(
        speed: digit.speed * 3,
      )).toList();
    });
    
    Future.delayed(const Duration(milliseconds: 800), _navigateToHome);
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildFallingDigits() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _fallingDigits.map((digit) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            return Positioned(
              left: digit.left * screenWidth / 100,
              top: digit.top * screenHeight / 100,
              child: Opacity(
                opacity: digit.opacity,
                child: Text(
                  digit.digit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: digit.size,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Courier',
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWatermarkIcon(IconData icon, double top, double left, double size) {
    return Positioned(
      top: top,
      left: left,
      child: Opacity(
        opacity: 0.08, // زيادة الشفافية لجعلها خلفية
        child: Icon(
          icon,
          size: size,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isAuthenticating ? null : _authenticate,
      child: Container(
        width: 220, // زيادة الحجم
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // دوائر متحدة المركز
            ...List.generate(4, (index) {
              return Container(
                width: 220 - index * 35,
                height: 220 - index * 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2 - index * 0.05),
                    width: 2,
                  ),
                ),
              );
            }),
            
            // أيقونة البصمة الكبيرة
            Icon(
              Icons.fingerprint,
              size: 100, // زيادة حجم الأيقونة
              color: AppColors.primary,
            ),
            
            // مؤشر التحميل
            if (_isAuthenticating)
              Positioned(
                bottom: 25,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // 1. الأرقام المتساقطة (خلفية)
          _buildFallingDigits(),
          
          // 2. العلامات المائية في الزوايا (متنوعة وأكبر)
          _buildWatermarkIcon(Icons.security, screenHeight * 0.05, screenWidth * 0.05, 60),
          _buildWatermarkIcon(Icons.lock, screenHeight * 0.05, screenWidth * 0.85, 60),
          _buildWatermarkIcon(Icons.verified_user, screenHeight * 0.85, screenWidth * 0.05, 60),
          _buildWatermarkIcon(Icons.enhanced_encryption, screenHeight * 0.85, screenWidth * 0.85, 60),
          
          // 3. أيقونات إضافية موزعة
          _buildWatermarkIcon(Icons.vpn_key, screenHeight * 0.15, screenWidth * 0.15, 45),
          _buildWatermarkIcon(Icons.shield, screenHeight * 0.15, screenWidth * 0.75, 45),
          _buildWatermarkIcon(Icons.privacy_tip, screenHeight * 0.75, screenWidth * 0.15, 45),
          _buildWatermarkIcon(Icons.safety_check, screenHeight * 0.75, screenWidth * 0.75, 45),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // العنوان في الأعلى
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 35,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'نظام تشفير AES-256',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Icon(Icons.lock_outline, size: 45, color: Colors.white.withOpacity(0.9)),
                      Text(
                        'أقصى درجات الحماية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'NotoKufiArabic',
                          height: 1.2,
                          
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'المصادقة الآمنة بالبصمة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 20,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  // أيقونة البصمة المركزية الكبيرة
                  Column(
                    children: [
                      _buildBiometricButton(),
                      const SizedBox(height: 40),
                      Text(
                        _isAuthenticating 
                            ? '🔐 جاري التحقق من الهوية الرقمية...'
                            : '👆 المس البصمة للوصول الآمن',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  // معلومات النظام في الأسفل
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSystemStatus('التشفير', Colors.green),
                        _buildSystemStatus('الأمان', Colors.green),
                        _buildSystemStatus('النظام', Colors.blue),
                        _buildSystemStatus('الاتصال', Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.7),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoKufiArabic',
          ),
        ),
      ],
    );
  }
}

class FallingDigit {
  final String digit;
  final double left; // نسبة مئوية
  final double top; // نسبة مئوية
  final double speed;
  final double size;
  final double opacity;
  
  FallingDigit({
    required this.digit,
    required this.left,
    this.top = 0,
    required this.speed,
    required this.size,
    required this.opacity,
  });
  
  FallingDigit copyWith({
    String? digit,
    double? left,
    double? top,
    double? speed,
    double? size,
    double? opacity,
  }) {
    return FallingDigit(
      digit: digit ?? this.digit,
      left: left ?? this.left,
      top: top ?? this.top,
      speed: speed ?? this.speed,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }
}