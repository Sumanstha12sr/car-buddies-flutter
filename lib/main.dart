import 'package:car_buddies/Screen/Auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'Screen/Auth/login_screen.dart';
import 'Screen/Auth/signup_screen.dart';
import 'Screen/Auth/login_selector_screen.dart';

void main() {
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
        '/loginselector': (context) => const LoginSelectorScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
