import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondary) => const AuthGate(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              const AppLogo(size: 88),
              const SizedBox(height: 28),
              Text('Firebase Task Manager', style: AppTheme.heading(26)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  'A simple task manager powered by Flutter & Firestore',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, height: 1.5, color: AppColors.muted),
                ),
              ),
              const Spacer(flex: 6),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text('Initializing app...',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.hint)),
              const SizedBox(height: 28),
              Text('FLUTTER  •  FIREBASE',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.hint)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}