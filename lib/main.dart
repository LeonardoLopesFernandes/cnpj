import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CnpjApp());
}

class CnpjApp extends StatelessWidget {
  const CnpjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta CNPJ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0d1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58a6ff),
          surface: Color(0xFF161b22),
        ),
        cardColor: const Color(0xFF161b22),
        dividerColor: const Color(0xFF21262d),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
