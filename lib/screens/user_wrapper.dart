import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_sceen.dart';

class UserWrapper extends StatefulWidget {
  const UserWrapper({super.key});

  @override
  State<UserWrapper> createState() => _UserWrapperState();
}

class _UserWrapperState extends State<UserWrapper>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget? _screen;

  /// 🎬 Animation
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    /// Setup animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    /// Delay then check user
    Future.delayed(const Duration(seconds: 3), () {
      _checkUser();
    });
  }

  Future<void> _checkUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() {
          _screen = UserLoginScreen();
        });
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        setState(() {
          _screen = SignUpScreen();
        });
        return;
      }

      setState(() {
        _screen = const HomeScreen();
      });
    } catch (e) {
      setState(() {
        _screen = UserLoginScreen();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 🔥 SHOW SPLASH FIRST
    if (_screen == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset('assets/logo2.png', height: 120),
            ),
          ),
        ),
      );
    }

    /// ✅ AFTER SPLASH → SHOW REAL SCREEN
    return _screen!;
  }
}
