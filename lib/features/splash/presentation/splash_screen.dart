import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/auth.dart';
import 'package:sikarir/main.dart';

class SplashScreen extends StatefulWidget {
  final Duration minDuration;

  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 2400),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _badgeScale;
  late Animation<double> _footerFade;
  late Animation<double> _pulseAnimation;

  String _loadingMessage = 'Menyiapkan portal karir...';
  Timer? _messageTimer1;
  Timer? _messageTimer2;

  @override
  void initState() {
    super.initState();

    // Main entrance controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Continuous pulse for glow aura
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sequence of animations
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeIn),
      ),
    );

    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeIn),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Rotate loading text for dynamic feel
    _startMessageCycle();

    // Perform initialization & routing after initial frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeApp();
      }
    });
  }

  void _startMessageCycle() {
    _messageTimer1 = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _loadingMessage = 'Memverifikasi sesi pelatihan...';
        });
        _messageTimer2 = Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _loadingMessage = 'Selamat datang di siKarir!';
            });
          }
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    final authProvider = context.read<AuthProvider>();

    // Ensure auth state is loaded
    if (!authProvider.isInitialized) {
      await authProvider.init();
    }

    // Wait for minimum splash screen duration for aesthetic animation enjoyment
    final elapsed = DateTime.now().difference(startTime);
    final remaining = widget.minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    final isAuthenticated = authProvider.isAuthenticated;
    final targetWidget = isAuthenticated
        ? const MainNavigationScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => targetWidget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curveAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curveAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curveAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer1?.cancel();
    _messageTimer2?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Layered Background with Deep Forest Gradients
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF07211C), // Rich midnight emerald
                  Color(0xFF0F3E34), // Core App Primary
                  Color(0xFF144D41), // Deep forest
                  Color(0xFF092922), // Bottom shadow depth
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // 2. Glowing Ambient Orbs for Premium Depth
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: size.width * 0.85,
                    height: size.width * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2ECC71).withValues(alpha: 0.18),
                          const Color(0xFF0F5B3E).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -size.width * 0.3,
            left: -size.width * 0.25,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 2.0 - _pulseAnimation.value,
                  child: Container(
                    width: size.width * 0.95,
                    height: size.width * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEE7D32).withValues(alpha: 0.14),
                          const Color(0xFF0F3E34).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Subtle Geometric Background Pattern Dots
          Positioned.fill(
            child: FadeTransition(
              opacity: _bgFade,
              child: CustomPaint(
                painter: _GeometricBackgroundPainter(),
              ),
            ),
          ),

          // 4. Main Center Content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Animated Hero Emblem
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glowing ring
                          Container(
                            width: 140 * _pulseAnimation.value,
                            height: 140 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.mint.withValues(alpha: 0.25 * (1.1 - (_pulseAnimation.value - 0.92))),
                                width: 2,
                              ),
                            ),
                          ),
                          // Second soft glow ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFEE7D32).withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(4, 4),
                                ),
                              ],
                            ),
                          ),
                          // Center Glassmorphic Squircle Badge
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1F6B5A),
                                      Color(0xFF0B332B),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Subtle diagonal highlight shine
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: 48,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(26),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.25),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Dual Icon Composition
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          color: Color(0xFF82E0AA),
                                          size: 44,
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 14,
                                      right: 14,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Sub-Badge "BLK CONNECT DIGITAL"
                  ScaleTransition(
                    scale: _badgeScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF82E0AA).withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFFFB366),
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'BLK DIGITAL ECOSYSTEM',
                            style: TextStyle(
                              color: Color(0xFFE8F8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Brand Title: siKarir
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                              children: [
                                TextSpan(
                                  text: 'si',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Karir',
                                  style: TextStyle(
                                    color: Color(0xFF82E0AA),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          const Text(
                            'Portal Karir & Pelatihan Vokasi',
                            style: TextStyle(
                              color: Color(0xFFD0ECE1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Membangun Keterampilan, Menghubungkan Masa Depan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Progress & Loading Message Indicator
                  FadeTransition(
                    opacity: _footerFade,
                    child: Column(
                      children: [
                        // Sleek Gradient Pill Progress Bar
                        Container(
                          width: 160,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF82E0AA),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _loadingMessage,
                            key: ValueKey<String>(_loadingMessage),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Official Kemnaker / BLK Branding Footer
                  FadeTransition(
                    opacity: _footerFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Color(0xFF82E0AA),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'KEMENTERIAN KETENAGAKERJAAN RI',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Balai Latihan Kerja • SIKARIR Mobile v1.0.0',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
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
}

/// Custom Background Painter for subtle geometric dot matrix
class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = 14; x < size.width; x += spacing) {
      for (double y = 14; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
