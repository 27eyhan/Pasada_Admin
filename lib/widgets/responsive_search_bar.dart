import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:provider/provider.dart';

class ResponsiveSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;
  final bool showFilterButton;
  final VoidCallback? onFilterPressed;

  const ResponsiveSearchBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.onClear,
    this.showFilterButton = false,
    this.onFilterPressed,
  });

  @override
  _ResponsiveSearchBarState createState() => _ResponsiveSearchBarState();
}

class _ResponsiveSearchBarState extends State<ResponsiveSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
    });
    widget.onSearchChanged(value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearchChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon and input field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 16.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: isMobile ? 18.0 : 20.0,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                  SizedBox(width: isMobile ? 8.0 : 12.0),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: isDark ? Palette.darkText : Palette.lightText,
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontFamily: 'Inter',
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                          fontSize: isMobile ? 14.0 : 16.0,
                          fontFamily: 'Inter',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_isSearching) ...[
                    SizedBox(width: isMobile ? 4.0 : 8.0),
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 4.0 : 6.0),
                        decoration: BoxDecoration(
                          color: isDark ? Palette.darkSurface : Palette.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: isMobile ? 14.0 : 16.0,
                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Filter button (if enabled)
          if (widget.showFilterButton) ...[
            Container(
              height: 1,
              width: 1,
              color: isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilterPressed,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(isMobile ? 8.0 : 12.0),
                  bottomRight: Radius.circular(isMobile ? 8.0 : 12.0),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 12.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: isMobile ? 18.0 : 20.0,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                      if (!isMobile) ...[
                        SizedBox(width: 6.0),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: isDark ? Palette.darkText : Palette.lightText,
                            fontSize: 14.0,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
