import 'package:flutter/material.dart';
import 'ui/check_page.dart';

void main() => runApp(const NetscanApp());

class NetscanApp extends StatelessWidget {
  const NetscanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Netscan',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff17654b),
        surface: const Color(0xfff7f8f4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const CheckPage(),
  );
}
