import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default to Sunlight (bright) mode as the primary experience.
/// Users can toggle to Moonlight (dark) in settings/profile.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
