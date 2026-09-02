import 'package:flutter/material.dart';

class SplashContent extends StatefulWidget {
   SplashContent({
    super.key,
  });

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent>  with SingleTickerProviderStateMixin{
   late AnimationController _animationController= AnimationController(
     vsync: this,
     duration: const Duration(milliseconds: 1000),
   );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7D6), // Matching Khadi Theme[cite: 1]
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeIn,
              ),
            ), //[cite: 1]
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent:
                  _animationController,

                  curve:
                  Curves.easeOut,
                ),
              ), //[cite: 1]
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