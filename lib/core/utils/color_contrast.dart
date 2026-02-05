import 'dart:ui';
import 'dart:math' as math;

/// Utility class for calculating WCAG color contrast ratios
class ColorContrast {
  /// Calculate the contrast ratio between two colors
  /// Returns a value between 1 and 21
  /// WCAG AA requires:
  /// - Normal text: 4.5:1
  /// - Large text: 3:1
  /// - UI components: 3:1
  static double calculateContrastRatio(Color color1, Color color2) {
    final lum1 = _calculateRelativeLuminance(color1);
    final lum2 = _calculateRelativeLuminance(color2);
    
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Calculate relative luminance of a color
  /// Formula from WCAG 2.0: https://www.w3.org/TR/WCAG20/#relativeluminancedef
  static double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorComponent(color.r);
    final g = _linearizeColorComponent(color.g);
    final b = _linearizeColorComponent(color.b);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// Linearize a color component value
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
  
  /// Parse hex color string to Color object
  static Color parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
  
  /// Check if contrast ratio meets WCAG AA standard for normal text (4.5:1)
  static bool meetsWCAGAANormalText(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }
  
  /// Check if contrast ratio meets WCAG AA standard for large text or UI (3:1)
  static bool meetsWCAGAALargeText(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 3.0;
  }
}
