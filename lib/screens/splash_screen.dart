import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/app/routes.dart';
import 'package:medreminder/utils/constants.dart';
import 'package:medreminder/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main icon scale animation
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  // Title fade + slide animation
  late final AnimationController _titleController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // Tagline fade animation
  late final AnimationController _taglineController;
  late final Animation<double> _taglineFade;

  // Shimmer pulse animation on the icon circle
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Bottom loader fade
  late final AnimationController _loaderController;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
    _navigateAfterSplash();
  }

  void _initAnimations() {
    // ── Icon Scale (bounce in) ──
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    // ── Title Fade + Slide Up ──
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));

    // ── Tagline Fade ──
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    // ── Pulse / Shimmer on icon circle ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Bottom loader ──
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loaderFade = CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeIn,
    );
  }

  void _startAnimationSequence() {
    // Icon bounces in immediately
    _iconController.forward();

    // Title fades + slides in after 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });

    // Tagline fades in after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _taglineController.forward();
    });

    // Pulse starts after icon finishes (800ms), repeats
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // Loader appears after 1200ms
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _loaderController.forward();
    });
  }

  void _navigateAfterSplash() {
    Future.delayed(AppConstants.splashDuration, () {
      if (!mounted) return;
      final route = StorageService.isRegistered
          ? AppRoutes.home
          : AppRoutes.registration;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _taglineController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // ── Animated Icon ──
              _buildAnimatedIcon(),
              const SizedBox(height: AppTheme.spacingLg),
              // ── Animated Title ──
              _buildAnimatedTitle(),
              const SizedBox(height: AppTheme.spacingSm),
              // ── Animated Tagline ──
              _buildAnimatedTagline(),
              const Spacer(flex: 3),
              // ── Bottom Loader ──
              _buildBottomLoader(),
              const SizedBox(height: AppTheme.spacing2Xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return ScaleTransition(
      scale: _iconScale,
      child: ScaleTransition(
        scale: _pulseScale,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 56,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Text(
          AppConstants.appName,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Text(
        AppConstants.appTagline,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.85),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomLoader() {
    return FadeTransition(
      opacity: _loaderFade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
