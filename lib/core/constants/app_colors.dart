import 'package:flutter/material.dart';

/// Float Financial Brand Colors
/// Directly inspired by the provided brand visuals:
/// - Bright "Sunlight" (default): crystal turquoise pool water, vibrant rainbow
///   inflatable float (red/orange/yellow/green/blue/purple segments), bright
///   orange tropical drink with rainbow umbrella, beach ball, sand/cream tones.
/// - "Moonlight" (toggle): the same scene after dark — deep navy water/sky
///   with the rainbow and drink colors glowing against the night.
///
/// App icon and logo treatments should reflect the active mode.
class AppColors {
  // ============================================
  // SUNLIGHT (Default Bright / Daylight mode)
  // ============================================
  // Crystal clear turquoise pool water (primary brand color)
  static const Color primaryTeal = Color(0xFF00C4CC);

  // Deeper ocean blue for gradients and secondary elements
  static const Color oceanBlue = Color(0xFF2AAFE0);

  // Sky blue accent
  static const Color skyBlue = Color(0xFF38BDF8);

  // Bright sunshine yellow / gold highlights
  static const Color sunshineYellow = Color(0xFFFFD93D);
  static const Color sunGold = Color(0xFFFFC94D);

  // Vibrant rainbow segments from the float (exact order inspired by visuals)
  static const Color floatRed = Color(0xFFFF4757);
  static const Color floatOrange = Color(0xFFFF8C42); // tropical drink orange
  static const Color floatYellow = Color(0xFFFFD93D);
  static const Color floatGreen = Color(0xFF6BCB77);
  static const Color floatBlue = Color(0xFF4D96FF);
  static const Color floatPurple = Color(0xFF9B6BD9);
  static const Color floatPink = Color(0xFFFF6F91); // coral/pink accent

  // Warm accents
  static const Color coral = Color(0xFFFF6F91);
  static const Color sunsetOrange = Color(0xFFFF9457);
  static const Color vibrantPurple = Color(0xFF9B6BD9);
  static const Color limeGreen = Color(0xFFA8D93B);

  // Backgrounds & neutrals (beach / sand vibe)
  static const Color deepNavy = Color(0xFF0B2545);
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFFFF8EE); // warm sand/cream
  static const Color sand = Color(0xFFFFF1DC);
  static const Color darkText = Color(0xFF1A1A2E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, oceanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bright sunrise / pool gradient (used in splash + hero areas)
  static const LinearGradient sunlightGradient = LinearGradient(
    colors: [sunGold, coral, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cruise mode hero gradient — directly inspired by the float image
  // Warm tropical orange-pink sunset melting into vibrant crystal pool teal
  static const LinearGradient cruiseGradient = LinearGradient(
    colors: [Color(0xFFFFA26B), Color(0xFFFF6B9D), Color(0xFF00D4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Lighter, brighter version for light mode cards (Sunlight pool day)
  static const LinearGradient cruiseGradientLight = LinearGradient(
    colors: [Color(0xFFFFB88A), Color(0xFFFF8FB3), Color(0xFF5AE0E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // MOONLIGHT (Dark mode toggle)
  // ============================================
  static const Color moonlightBackground = Color(0xFF071021);
  static const Color moonlightSurface = Color(0xFF102A43);
  static const Color moonlightSurfaceAlt = Color(0xFF16324F);
  static const Color moonlightText = Color(0xFFE6F1F5);
  static const Color moonlightAccent = Color(0xFF5EEAD4); // glowing cyan on water
  static const Color moonlightSilver = Color(0xFFCBD5E1);
  static const Color moonlightPurple = Color(0xFFA78BFA);
  static const Color moonlightCoral = Color(0xFFFCA5A5);
  static const Color moonlightGold = Color(0xFFF5C976);

  // Extra glow for deep water feel in Moonlight
  static const Color moonlightGlow = Color(0xFF67E8F9);
  static const Color moonlightDeepWater = Color(0xFF0A1C33);

  static const LinearGradient moonlightGradient = LinearGradient(
    colors: [moonlightDeepWater, Color(0xFF0C2233), Color(0xFF124047)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
