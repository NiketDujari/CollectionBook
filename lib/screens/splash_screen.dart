import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Setup entrance animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent:
            _animationController,

            curve:
            Curves.easeOut,
          ),
        );
    _navigationTimer = Timer(
      const Duration(seconds: 0),
      _navigateNext,
    );

    _animationController.forward();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    User? user =
        FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7D6), // Matching Khadi Theme[cite: 1]
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation, //[cite: 1]
            child: ScaleTransition(
              scale: _scaleAnimation, //[cite: 1]
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, //[cite: 1]
                children: [
                  const Spacer(), //[cite: 1]

                  // --- NEW: App Logo Image ---
                  Image.asset(
                    'assets/logo-transparent.png', // Replace with your actual image path
                    width: 300,
                    height: 300,
                  ),

                  const Spacer(), //[cite: 1]
                  // Loading Indicator[cite: 1]
                  const SizedBox(
                    width: 24, //[cite: 1]
                    height: 24, //[cite: 1]
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, //[cite: 1]
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFC98A2D), //[cite: 1]
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), //[cite: 1]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}