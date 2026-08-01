import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TierUtils {
  static const String drifterDeck = 'Drifter Deck';
  static const String buoyBrigade = 'Buoy Brigade';
  static const String captainsCurrent = 'Captain\'s Current';

  /// Maximum number of active alerts allowed per tier
  static int getMaxAlerts(String tier) {
    switch (tier) {
      case drifterDeck:
        return 3;
      case buoyBrigade:
        return 10;
      case captainsCurrent:
        return 999; // unlimited
      default:
        return 3;
    }
  }

  /// Can access detailed reports
  static bool canAccessReports(String tier) {
    return tier == buoyBrigade || tier == captainsCurrent;
  }

  /// Can access admin features
  static bool canAccessAdmin(String tier, String role) {
    return role == 'admin' || tier == captainsCurrent;
  }

  /// Get tier color for UI
  static Color getTierColor(String tier) {
    switch (tier) {
      case captainsCurrent:
        return AppColors.vibrantPurple;
      case buoyBrigade:
        return AppColors.primaryTeal;
      default:
        return AppColors.oceanBlue;
    }
  }
}