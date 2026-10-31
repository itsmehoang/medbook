import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme();

  // Bảng màu chuẩn Modern Medical App (Material 3)
  static const Color primaryColor = Color(0xFF0284C7); // Xanh y tế chủ đạo (Sky 600)
  static const Color primaryDark = Color(0xFF0369A1);  // Sky 700 (Dùng cho gradient Header)
  static const Color primaryLight = Color(0xFFE0F2FE); // Sky 100 (Nền pastel nhẹ)

  static const Color accentColor = Color(0xFF0D9488);  // Xanh ngọc (Teal 600)
  static const Color accentLight = Color(0xFFCCFBF1);  // Teal 100 (Nền nhấn pastel)

  static const Color backgroundColor = Color(0xFFF4F7FA); // Nền ứng dụng sạch sẽ, hiện đại
  static const Color cardColor = Color(0xFFFFFFFF);        // Màu Card trắng tinh khiết

  static const Color successColor = Color(0xFF10B981); // Xanh lá hoàn thành / Đã uống thuốc (Emerald 500)
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorColor = Color(0xFFEF4444);   // Red 500
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900 (Đen than sang trọng)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0);   // Slate 200 (Viền nhẹ tinh tế)

  // Gradient nhận diện thương hiệu MEDBOOK
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Đổ bóng mềm mại chuẩn Clean UI (Không dùng viền thô)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0284C7).withOpacity(0.18),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  ThemeData get themeData {
    final textTheme = GoogleFonts.ibmPlexSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: accentColor,
        onSecondary: Colors.white,
        secondaryContainer: accentLight,
        onSecondaryContainer: const Color(0xFF115E59),
        tertiary: successColor,
        onTertiary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        errorContainer: errorLight,
        onErrorContainer: const Color(0xFF991B1B),
        surface: cardColor,
        onSurface: textPrimary,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: textTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: textTheme.titleSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

