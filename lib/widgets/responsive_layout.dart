import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? minWidth;
  final bool enableHorizontalScroll;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.minWidth,
    this.enableHorizontalScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final effectiveMinWidth = isMobile ? 0.0 : (minWidth ?? 900.0);
    final effectiveWidth = ResponsiveHelper.getResponsiveWidth(
      context,
      minWidth: effectiveMinWidth,
    );

    Widget content = SizedBox(
      width: effectiveWidth,
      child: child,
    );

    // Only enable horizontal scrolling on desktop/tablet when needed
    if (enableHorizontalScroll && !isMobile && effectiveWidth > MediaQuery.of(context).size.width) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: effectiveMinWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);
    return Padding(
      padding: responsivePadding,
      child: child,
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.crossAxisSpacing = 24.0,
    this.mainAxisSpacing = 24.0,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
      largeDesktop: largeDesktopColumns ?? 4,
    );

    final isMobile = ResponsiveHelper.isMobile(context);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: isMobile 
          ? const BouncingScrollPhysics() 
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? 14.0,
      tablet: tabletFontSize ?? 16.0,
      desktop: desktopFontSize ?? 18.0,
    );

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
