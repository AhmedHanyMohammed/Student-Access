import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../Services/auth_service.dart';
import 'event_list.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // TODO: point this at your actual Lottie file from LottieFiles.
  static const _animationAsset = 'assets/animations/splash.json';

  bool _hasNavigated = false;

  Future<void> _goToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final isLoggedIn = await AuthService.instance.isLoggedIn();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            isLoggedIn ? const EventListScreen() : const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF),
      body: Center(
        child: Lottie.asset(
          _animationAsset,
          width: 240,
          height: 240,
          repeat: false,
          onLoaded: (composition) {
            // Navigate once the animation finishes playing.
            Future.delayed(composition.duration, _goToNext);
          },
          errorBuilder: (context, error, stackTrace) {
            // If the asset is missing/misconfigured, don't get stuck —
            // fall back to a short timer so the app still flows.
            Future.delayed(const Duration(seconds: 2), _goToNext);
            return const Icon(
              Icons.qr_code_2_rounded,
              size: 96,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }
}
