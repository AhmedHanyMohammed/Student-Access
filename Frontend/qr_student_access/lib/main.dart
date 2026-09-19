import 'package:flutter/material.dart';
import 'Screens/event_list.dart';
import 'Screens/login.dart';
import 'Screens/my_pass.dart';
import 'Screens/register.dart';
import 'Screens/scanner.dart';
import 'Screens/splash.dart';

void main() {
  runApp(const EventPassApp());
}

class EventPassApp extends StatelessWidget {
  const EventPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Pass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        EventListScreen.routeName: (_) => const EventListScreen(),
        MyQrPassScreen.routeName: (_) => const MyQrPassScreen(),
        ScannerScreen.routeName: (_) => const ScannerScreen(),
      },
    );
  }
}
