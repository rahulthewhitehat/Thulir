import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Navigate after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _navigateBasedOnAuth(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateBasedOnAuth(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.emailVerified) {
        // Check if user details are already entered in 'user_info' collection
        final userDoc = await FirebaseFirestore.instance
            .collection('user_info') // Corrected collection name
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['name'] != null) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/userDetails');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Stack(
        children: [
          // Center content of the splash screen
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 250),
                  const SizedBox(height: 20),
                  Text(
                    'Thulir',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700, // Matching app theme color
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your One Stop College Companion!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green.shade600, // Matching app theme color
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ),
          // Footer with heart and name
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min, // Align the row in the center
                children: [
                  Text(
                    'Made with ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700, // Matching app theme color
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: Colors.red, // Heart icon in red
                    size: 16,
                  ),
                  const SizedBox(width: 4), // Small space between heart and username
                  Text(
                    '@rahulthewhitehat',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700, // Matching app theme color
                      fontWeight: FontWeight.bold,
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
