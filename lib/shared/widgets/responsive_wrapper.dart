import 'package:flutter/material.dart';

/// Responsive wrapper that adapts layout for mobile screens
/// Use this to wrap dashboard sections that need mobile optimization
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : (isTablet ? 600 : maxWidth),
        ),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 8 : 16,
        ),
        child: child,
      ),
    );
  }
}

/// Responsive grid that switches to single column on mobile
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.desktopColumns = 2,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        children: children.map((child) => Padding(
          padding: EdgeInsets.only(bottom: runSpacing),
          child: child,
        )).toList(),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) => SizedBox(
        width: (screenWidth - (desktopColumns + 1) * spacing) / desktopColumns,
        child: child,
      )).toList(),
    );
  }
}

/// Responsive text that scales for mobile
class ResponsiveText extends StatelessWidget {
  final String text;
  final double desktopFontSize;
  final double mobileFontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.desktopFontSize = 16,
    this.mobileFontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: isMobile ? mobileFontSize : desktopFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// Check if current screen is mobile
bool isMobileScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

/// Check if current screen is tablet
bool isTabletScreen(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 600 && width < 1024;
}

/// Check if current screen is desktop
bool isDesktopScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 1024;
}
