import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically navigate to login page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF091E3A),
                  Color(0xFF2D9EE0),
                  Color(0xFF2E8FE7),
                  // Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.4, 0.8],
              ),
            ),
          ),

          // Background GIF
          Opacity(
            opacity: 0.2,
            child: SizedBox.expand(
              child: Image.asset(
                'assets/walk.gif',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 2), // spacing from top

                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 350, // responsive size if needed
                    width: 350,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 120),

                // Description text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Unlock Personalized career\npaths in AI based on\nyour Skills & goals',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(), // pushes the button to bottom

                // LOGIN button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF091E3A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40), // spacing from bottom
              ],
            ),
          ),
        ],
      ),
    );
  }
}
