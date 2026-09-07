import 'package:flutter/material.dart';

class Paleta {
  final Color primary;
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color box;
  final Color success;
  final Color warning;
  final Color error;
  final Color muted;

  const Paleta({
    required this.primary,
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.box,
    required this.success,
    required this.warning,
    required this.error,
    required this.muted,
  });
}

class PaletaTema {
  PaletaTema._();

  static Paleta of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? clara : escura;

  static const clara = Paleta(
    primary: Color(0xFF0A6CFF),
    bg: Color(0xFFF4F6FA),
    card: Colors.white,
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0B1B33),
    textSecondary: Color(0xFF64748B),
    box: Color(0xFFF1F5F9),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    muted: Color(0xFF94A3B8),
  );

  static const escura = Paleta(
    primary: Color(0xFF4A90D9),
    bg: Color(0xFF0F1724),
    card: Color(0xFF162033),
    border: Color(0xFF1E3A5F),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFFB6C2D2),
    box: Color(0xFF1A2538),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    muted: Color(0xFF7D8DA3),
  );
}
