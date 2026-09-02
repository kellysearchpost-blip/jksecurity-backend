import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import 'office_dashboard_screen.dart';

void main() {
  runApp(const JKSecurityApp());
}

class JKSecurityApp extends StatelessWidget {
  const JKSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JK Security Ops',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/dashboard': (context) => const OfficeDashboardScreen(),
      },
    );
  }
}