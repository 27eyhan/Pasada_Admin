import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:provider/provider.dart';

class TablePreviewWidget extends StatefulWidget {
  final String tableName;
  final String tableDescription;
  final IconData tableIcon;
  final Color tableColor;
  final Future<List<Map<String, dynamic>>> Function() dataFetcher;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<Map<String, dynamic>> data) rowBuilder;
  final VoidCallback? onRefresh;
  final Duration? refreshInterval;
  final bool showFilterButton;
  final VoidCallback? onFilterPressed;
  final Widget? customActions;
  final bool includeNavigation; // New parameter to control navigation inclusion

  const TablePreviewWidget({
    super.key,
    required this.tableName,
    required this.tableDescription,
    required this.tableIcon,
    required this.tableColor,
    required this.dataFetcher,
    required this.columns,
    required this.rowBuilder,
    this.onRefresh,
    this.refreshInterval,
    this.showFilterButton = false,
    this.onFilterPressed,
    this.customActions,
    this.includeNavigation = true, // Default to true for backward compatibility
  });

  @override
  State<TablePreviewWidget> createState() => _TablePreviewWidgetState();
}

class _TablePreviewWidgetState extends State<TablePreviewWidget>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> tableData = [];
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
    _fetchData();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    _loadingController.forward();

    try {
      final data = await widget.dataFetcher();
      if (mounted) {
        setState(() {
          tableData = data;
          isLoading = false;
          hasError = false;
        });
        _loadingController.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
        _loadingController.reset();
      }
    }
  }

  void _handleRefresh() {
    _fetchData();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.05;

    // If navigation should be included, wrap in Scaffold with navigation
    if (widget.includeNavigation) {
      return Scaffold(
        backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
        body: LayoutBuilder(
          builder: (context, constraints) {
            const double minBodyWidth = 900;
            final double effectiveWidth = constraints.maxWidth < minBodyWidth
                ? minBodyWidth
                : constraints.maxWidth;
            
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minBodyWidth),
                child: SizedBox(
                  width: effectiveWidth,
                  child: Row(
                    children: [
                      // Fixed width sidebar drawer
                      SizedBox(
                        width: 280,
                        child: MyDrawer(),
                      ),
                      // Main content area
                      Expanded(
                        child: Column(
                          children: [
                            // App bar in the main content area
                            AppBarSearch(
                              onFilterPressed: widget.showFilterButton 
                                  ? widget.onFilterPressed 
                                  : null,
                            ),
                            // Main content
                            Expanded(
                              child: _buildMainContent(isDark, horizontalPadding),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // If navigation should not be included, return just the content
      return Container(
        color: isDark ? Palette.darkSurface : Palette.lightSurface,
        child: _buildMainContent(isDark, horizontalPadding),
      );
    }
  }

  Widget _buildMainContent(bool isDark, double horizontalPadding) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 24.0,
          horizontal: horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeader(isDark),
            const SizedBox(height: 24.0),
            
            // Stats container
            _buildStatsContainer(isDark),
            const SizedBox(height: 24.0),
            
            // Actions row
            _buildActionsRow(isDark),
            const SizedBox(height: 16.0),
            
            // Table content
            _buildTableContent(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Back button
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Palette.darkBorder : Palette.lightBorder,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: IconButton(
            iconSize: 28.0,
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16.0),
        
        // Table icon with colored background
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.tableColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.tableIcon,
            size: 28,
            color: widget.tableColor,
          ),
        ),
        const SizedBox(width: 16.0),
        
        // Table name and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tableName,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                widget.tableDescription,
                style: TextStyle(
                  fontSize: 14.0,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        
        // Custom actions
        if (widget.customActions != null) widget.customActions!,
      ],
    );
  }

  Widget _buildStatsContainer(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactMetric(
              'Total Records',
              tableData.length,
              isDark ? Palette.darkText : Palette.lightText,
              isDark,
            ),
          ),
          _buildVerticalSeparator(isDark),
          Expanded(
            child: _buildCompactMetric(
              'Status',
              hasError ? 'Error' : (isLoading ? 'Loading' : 'Active'),
              hasError 
                  ? Palette.lightError 
                  : (isLoading ? Palette.lightWarning : Palette.lightSuccess),
              isDark,
            ),
          ),
          _buildVerticalSeparator(isDark),
          Expanded(
            child: _buildCompactMetric(
              'Last Updated',
              DateTime.now().toString().substring(11, 19),
              isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Refresh button
        Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
              color: isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              size: 18,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
            onPressed: isLoading ? null : _handleRefresh,
            tooltip: 'Refresh Data',
          ),
        ),
        
        // Filter button (if enabled)
        if (widget.showFilterButton)
          Container(
            decoration: BoxDecoration(
              color: isDark ? Palette.darkCard : Palette.lightCard,
              border: Border.all(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                size: 18,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
              onPressed: widget.onFilterPressed,
              tooltip: 'Filter Data',
            ),
          ),
      ],
    );
  }

  Widget _buildTableContent(bool isDark) {
    if (isLoading) {
      return _buildLoadingState(isDark);
    }
    
    if (hasError) {
      return _buildErrorState(isDark);
    }
    
    if (tableData.isEmpty) {
      return _buildEmptyState(isDark);
    }
    
    return _buildDataTable(isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_loadingAnimation.value * 0.4),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.tableColor),
                    strokeWidth: 3.0,
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              'Loading ${widget.tableName} data...',
              style: TextStyle(
                fontSize: 16.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Please wait while we fetch the latest information',
              style: TextStyle(
                fontSize: 12.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Palette.lightError,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Failed to load ${widget.tableName} data',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: isDark ? Palette.darkText : Palette.lightText,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.tableColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            const SizedBox(height: 16.0),
            Text(
              'No ${widget.tableName} data found',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: isDark ? Palette.darkText : Palette.lightText,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'There are currently no records in this table',
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              columnSpacing: 24.0,
              horizontalMargin: 16.0,
              headingRowHeight: 56.0,
              dataRowMinHeight: 48.0,
              dataRowMaxHeight: 64.0,
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return isDark 
                      ? Palette.darkSurface.withValues(alpha: 0.5)
                      : Palette.lightSurface.withValues(alpha: 0.5);
                },
              ),
              columns: widget.columns.map((column) {
                return DataColumn(
                  label: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 14.0,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    child: column.label,
                  ),
                );
              }).toList(),
              rows: widget.rowBuilder(tableData).map((row) {
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return isDark 
                            ? Palette.darkBorder.withValues(alpha: 0.3)
                            : Palette.lightBorder.withValues(alpha: 0.3);
                      }
                      return null;
                    },
                  ),
                  cells: row.cells.map((cell) {
                    return DataCell(
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 14.0,
                          fontFamily: 'Inter',
                          color: isDark ? Palette.darkText : Palette.lightText,
                        ),
                        child: cell.child,
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetric(String label, dynamic value, Color valueColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            letterSpacing: 0.6,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalSeparator(bool isDark) {
    return Container(
      height: 40.0,
      width: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkDivider : Palette.lightDivider,
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }
}
