import 'package:car_buddies/Screen/Auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screen/Auth/login_screen.dart';
import 'Screen/Auth/signup_screen.dart';

void main() async {
  // ── Must be first before any async calls ──────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── Pre-initialize SharedPreferences so token is ready immediately
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
