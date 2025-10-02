import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';

class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String title;
  final IconData? titleIcon;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final EdgeInsets? padding;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveDialog({
    super.key,
    required this.child,
    required this.title,
    this.titleIcon,
    this.onClose,
    this.showCloseButton = true,
    this.padding,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate responsive dimensions
    final double dialogWidth = ResponsiveHelper.isMobile(context)
        ? screenSize.width * 0.95
        : ResponsiveHelper.isTablet(context)
            ? screenSize.width * 0.7
            : screenSize.width * 0.5;

    // Use as maxHeight only so the dialog can shrink to fit content
    final double dialogMaxHeight = ResponsiveHelper.isMobile(context)
        ? screenSize.height * 0.9
        : ResponsiveHelper.isTablet(context)
            ? screenSize.height * 0.8
            : screenSize.height * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        side: BorderSide(
          color: isDark ? Palette.darkBorder : Palette.lightBorder, 
          width: 1.5
        ),
      ),
      elevation: 8.0,
      backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? dialogWidth,
          maxHeight: maxHeight ?? dialogMaxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Responsive header
            _buildResponsiveHeader(context, isDark),

            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: padding ?? EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader(BuildContext context, bool isDark) {
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context);
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    final padding = ResponsiveHelper.getResponsiveCardPadding(context);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
          topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Palette.darkBorder.withValues(alpha: 77)
                : Palette.lightBorder.withValues(alpha: 77),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (titleIcon != null) ...[
            CircleAvatar(
              radius: ResponsiveHelper.getResponsiveAvatarRadius(context),
              backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
              child: Icon(
                titleIcon,
                color: isDark ? Palette.darkText : Palette.lightText,
                size: iconSize,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Palette.darkText : Palette.lightText,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (showCloseButton)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClose ?? () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
                  decoration: BoxDecoration(
                    color: isDark ? Palette.darkBorder : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: iconSize * 0.8,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ResponsiveDialogContent extends StatelessWidget {
  final List<Widget> children;
  final bool isScrollable;
  final EdgeInsets? padding;

  const ResponsiveDialogContent({
    super.key,
    required this.children,
    this.isScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    if (isScrollable) {
      return SingleChildScrollView(
        padding: padding ?? EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
        child: content,
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      child: content,
    );
  }
}

class ResponsiveDialogActions extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;

  const ResponsiveDialogActions({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        left: ResponsiveHelper.getResponsiveCardPadding(context),
        right: ResponsiveHelper.getResponsiveCardPadding(context),
        top: ResponsiveHelper.getResponsiveCardPadding(context),
        bottom: ResponsiveHelper.isMobile(context) 
            ? ResponsiveHelper.getResponsiveCardPadding(context)
            : ResponsiveHelper.getResponsiveCardPadding(context) * 0.4,
      ),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
          bottomRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        ),
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Palette.darkBorder.withValues(alpha: 77)
                : Palette.lightBorder.withValues(alpha: 77),
            width: 1.0,
          ),
        ),
      ),
      child: ResponsiveHelper.isMobile(context)
          ? Column(
              children: children.map((child) => 
                Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context)),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ).toList(),
            )
          : (children.length == 1
              ? Row(
                  children: [
                    Expanded(child: children.first),
                  ],
                )
              : Row(
                  mainAxisAlignment: alignment,
                  children: children,
                )),
    );
  }
}
