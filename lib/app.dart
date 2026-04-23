import 'package:flutter/material.dart';
import 'di/service_locator.dart';
import 'screens/home_screen.dart';
import '../packages/core/lib/src/utils/logger.dart';

// ============================================================
// ROOT APP
// ============================================================

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Native Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF03DAC6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
