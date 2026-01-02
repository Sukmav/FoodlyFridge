// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (based on your image #7C4585)
  static const Color primary = Color(0xFF7C4585);
  static const Color primaryLight = Color(0xFF9A6BA5);
  static const Color primaryDark = Color(0xFF5D3364);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFB53929);
  static const Color secondaryLight = Color(0xFFD14633);
  
  // Accent Colors
  static const Color accent = Color(0xFF7A9B3B);
  static const Color accentLight = Color(0xFF95B44A);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF1F3F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);
  
  // Border Colors
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderLight = Color(0xFFE9ECEF);
  
  // Semantic Colors for Dashboard Items
  static const Color stockIn = Color(0xFF4A90E2);
  static const Color stockOut = Color(0xFFF5A623);
  static const Color menu = Color(0xFF9B59B6);
  static const Color report = Color(0xFF3498DB);
  static const Color staff = Color(0xFF2ECC71);
  static const Color vendor = Color(0xFFE67E22);
  static const Color history = Color(0xFF95A5A6);
  static const Color cashier = Color(0xFF1ABC9C);
  static const Color settings = Color(0xFF7F8C8D);
  static const Color tutorial = Color(0xFFF39C12);

  //category colors
  static const Color categoryFood = Color(0xFF8B5FBF); // Makanan
  static const Color categoryDrink = Color(0xFF2196F3); // Minuman
  static const Color categoryDessert = Color(0xFFE91E63); // Dessert
  static const Color categorySnack = Color(0xFFFF9800); // Snack
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  ); 
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  // New Gradients for better visuals
  static const LinearGradient categoryFoodGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8B5FBF), Color(0xFF7C4585)],
  ); 

  static const LinearGradient categoryDrinkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF29B6F6), Color(0xFF17A2B8)],
  );
  
  static const LinearGradient categoryDessertGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF48FB1), Color(0xFFE91E63)],
  );
  
  static const LinearGradient categorySnackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
  );
  
  // Background Gradients
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, Color(0xFF8B5FBF)],
  );

  // Gradient Colors for Price Tags
  static const LinearGradient priceTagGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9C4DFF), // Ungu neon cerah
      Color(0xFF7B2CBF), // Ungu royal
      Color(0xFF5A189A), // Ungu gelap elegan
    ],
    stops: [0.0, 0.5, 1.0], // Membuat transisi lebih smooth
  );

  // Atau versi lebih sederhana dengan 2 warna:
  static const LinearGradient priceTagGradientSimple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFBA68C8), // Ungu lavender cerah
      Color(0xFF7B1FA2), // Ungu ungu menyala
    ],
  );

  // Versi gradient untuk teks kontras yang bagus:
  static const LinearGradient priceTagGradientVibrant = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFD500F9), // Ungu neon menyala
      Color(0xFFAA00FF), // Ungu elektrik
    ],
  );      
}