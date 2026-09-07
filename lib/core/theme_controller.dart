import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> modo =
      ValueNotifier(ThemeMode.light);

  static Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString('cnpj.tema') ?? 'claro';
      modo.value =
          salvo == 'escuro' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static Future<void> definirEscuro(bool escuro) async {
    modo.value = escuro ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cnpj.tema', escuro ? 'escuro' : 'claro');
    } catch (_) {}
  }
}
