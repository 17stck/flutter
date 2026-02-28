// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A73E8);
  static const secondary = Color(0xFF34A853);
  static const accent = Color(0xFFFBBC04);
  static const danger = Color(0xFFEA4335);
  static const warning = Color(0xFFFF9800);
  static const background = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF6B7280);
  static const cardShadow = Color(0x1A000000);

  // Status Colors
  static const statusNormal = Color(0xFF34A853);
  static const statusDamaged = Color(0xFFEA4335);
  static const statusRepairing = Color(0xFFFF9800);
  static const statusDisposed = Color(0xFF9E9E9E);
  static const statusLost = Color(0xFF7B1FA2);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Sarabun',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Sarabun',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// Status Color Helper
Color getStatusColor(String status) {
  switch (status) {
    case 'normal':
      return AppColors.statusNormal;
    case 'damaged':
      return AppColors.statusDamaged;
    case 'repairing':
      return AppColors.statusRepairing;
    case 'disposed':
      return AppColors.statusDisposed;
    case 'lost':
      return AppColors.statusLost;
    default:
      return AppColors.statusNormal;
  }
}

String getStatusLabel(String status) {
  switch (status) {
    case 'normal':
      return 'ปกติ';
    case 'damaged':
      return 'ชำรุด';
    case 'repairing':
      return 'รอซ่อม';
    case 'disposed':
      return 'จำหน่ายออก';
    case 'lost':
      return 'สูญหาย';
    default:
      return 'ปกติ';
  }
}

IconData getStatusIcon(String status) {
  switch (status) {
    case 'normal':
      return Icons.check_circle;
    case 'damaged':
      return Icons.broken_image;
    case 'repairing':
      return Icons.build;
    case 'disposed':
      return Icons.delete_forever;
    case 'lost':
      return Icons.search_off;
    default:
      return Icons.check_circle;
  }
}
