import 'package:flutter/material.dart';

/// BuildContext extension methods.
extension ContextExtension on BuildContext {
  /// Access theme data.
  ThemeData get theme => Theme.of(this);

  /// Access text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Access color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Access media query.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width.
  double get screenWidth => mediaQuery.size.width;

  /// Screen height.
  double get screenHeight => mediaQuery.size.height;

  /// Check if dark mode.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Show snackbar.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
