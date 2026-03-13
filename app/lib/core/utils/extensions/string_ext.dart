/// String extension methods.
extension StringExtension on String {
  /// Capitalize the first letter.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid email.
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid phone number (Vietnam).
  bool get isValidPhone {
    return RegExp(r'^(0|\+84)[3|5|7|8|9]\d{8}$').hasMatch(this);
  }

  /// Truncate string with ellipsis.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
