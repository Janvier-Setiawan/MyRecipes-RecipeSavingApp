import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern food-inspired color palette
  static const Color primaryColor = Color(0xFFE53E3E); // Rich tomato red
  static const Color secondaryColor = Color(0xFF38A169); // Fresh basil green
  static const Color accentColor = Color(0xFFFFB347); // Golden yellow
  static const Color backgroundColor = Color(0xFFFFFDF7); // Warm white
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2D3748); // Dark slate
  static const Color textSecondaryColor = Color(0xFF4A5568); // Medium slate
  static const Color successColor = Color(0xFF38A169); // Green
  static const Color warningColor = Color(0xFFECC94B); // Amber
  static const Color errorColor = Color(0xFFE53E3E); // Red
  static const Color surfaceColor = Color(0xFFF7FAFC); // Light gray

  // Text styling with modern typography
  static TextTheme textTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.inter(color: textPrimaryColor, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: textSecondaryColor, fontSize: 12),
      labelLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Get ThemeData with modern design
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: cardColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
        hintStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
      ),
      textTheme: textTheme(),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
