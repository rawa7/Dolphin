import 'package:flutter/material.dart';

/// App Colors based on Dolphin Shipping logo
/// Logo colors: Navy Blue (#1E3A5F) and White (#FFFFFF)
class AppColors {
  // Primary Colors from Logo
  static const Color primary = Color(0xFF1E3A5F); // Dark Navy Blue (logo background)
  static const Color primaryDark = Color(0xFF152B47); // Darker navy for depth
  static const Color primaryLight = Color(0xFF2B4A6F); // Lighter navy for highlights
  
  static const Color secondary = Color(0xFF4A90E2); // Bright blue for accents
  static const Color secondaryLight = Color(0xFF6BA5E7); // Light blue
  static const Color secondaryDark = Color(0xFF357ABD); // Darker blue
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGray = Color(0xFFE9ECEF);
  static const Color gray = Color(0xFF6C757D);
  static const Color darkGray = Color(0xFF343A40);
  static const Color black = Color(0xFF000000);
  
  // Status Colors
  static const Color success = Color(0xFF28A745); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFDC3545); // Red
  static const Color info = Color(0xFF17A2B8); // Cyan
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA); // Light gray background
  static const Color surface = Color(0xFFFFFFFF); // White surface
  static const Color cardBackground = Color(0xFFFFFFFF); // Card background
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E3A5F); // Navy for headings
  static const Color textSecondary = Color(0xFF6C757D); // Gray for body text
  static const Color textLight = Color(0xFFFFFFFF); // White text on dark bg
  static const Color textHint = Color(0xFF9CA3AF); // Light gray for hints
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A5F), // Dark navy
    Color(0xFF2B4A6F), // Medium navy
    Color(0xFF4A90E2), // Bright blue
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF4A90E2), // Bright blue
    Color(0xFF6BA5E7), // Light blue
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFF8F9FA), // Light gray
    Color(0xFFFFFFFF), // White
  ];
  
  // Order Status Colors
  static const Color pending = Color(0xFFFFC107); // Amber
  static const Color processing = Color(0xFF4A90E2); // Blue
  static const Color shipped = Color(0xFF17A2B8); // Cyan
  static const Color delivered = Color(0xFF28A745); // Green
  static const Color cancelled = Color(0xFFDC3545); // Red
  
  // Account Type Badge Colors
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color silverBadge = Color(0xFFC0C0C0);
  static const Color bronzeBadge = Color(0xFFCD7F32);
  static const Color standardBadge = Color(0xFF6C757D);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000); // 10% black
  static const Color shadowLight = Color(0x0D000000); // 5% black
  static const Color shadowDark = Color(0x33000000); // 20% black
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40000000); // 25% black
}

/// App Theme Data
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

