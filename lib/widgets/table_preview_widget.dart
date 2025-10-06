import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
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
  // Archive actions
  final Future<bool> Function()? onRecover; // When provided, shows a Recover action (async with result)
  final void Function(bool alsoDownloadPdf)? onDelete; // Shows Delete with confirmation; bool indicates whether to also download PDF
  final VoidCallback? onDownloadPdf; // Optional separate Download PDF action
  final Future<bool> Function()? onArchive; // Optional Archive action (async with result)
  // Selection
  final bool enableRowSelection; // When true, allows selecting a single row
  final ValueChanged<Map<String, dynamic>?>? onSelectionChanged; // Emits selected row (or null)
  final bool includeNavigation; // New parameter to control navigation inclusion
  final VoidCallback? onBackPressed; // Callback for back button navigation

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
    this.onRecover,
    this.onDelete,
    this.onDownloadPdf,
    this.onArchive,
    this.enableRowSelection = false,
    this.onSelectionChanged,
    this.includeNavigation = true, // Default to true for backward compatibility
    this.onBackPressed, // Callback for back button navigation
  });

  @override
  State<TablePreviewWidget> createState() => _TablePreviewWidgetState();
}

class _TablePreviewWidgetState extends State<TablePreviewWidget>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> paginatedData = [];
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  bool _deleteAlsoDownloadPdf = false; // state for delete confirmation option
  int? _selectedGlobalIndex; // selected index within tableData (global, not just current page)
  
  // Horizontal scroll controller for data table
  final ScrollController _tableHorizontalController = ScrollController();
  
  // Pagination state
  int currentPage = 1;
  int itemsPerPage = 25;
  int totalItems = 0;
  int totalPages = 0;

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
    _tableHorizontalController.dispose();
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
          totalItems = data.length;
          totalPages = (totalItems / itemsPerPage).ceil();
          _updatePaginatedData();
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

  void _updatePaginatedData() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, tableData.length);
    paginatedData = tableData.sublist(startIndex, endIndex);
  }

  void _onPageChanged(int page) {
    setState(() {
      currentPage = page;
      _updatePaginatedData();
    });
  }

  void _onItemsPerPageChanged(int newItemsPerPage) {
    setState(() {
      itemsPerPage = newItemsPerPage;
      totalPages = (totalItems / itemsPerPage).ceil();
      currentPage = 1; // Reset to first page
      _updatePaginatedData();
    });
  }

  void _handleRefresh() {
    _fetchData();
    widget.onRefresh?.call();
  }

  Future<void> _handleArchive() async {
    if (widget.onArchive == null) return;
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final bool ok = await (widget.onArchive!.call());
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Archived successfully.' : 'Failed to archive.'),
          backgroundColor: ok ? Palette.lightSuccess : Palette.lightError,
          duration: const Duration(seconds: 2),
        ),
      );
      // Always refresh to reflect changes
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Palette.lightError,
          duration: const Duration(seconds: 2),
        ),
      );
      await _fetchData();
    }
  }

  Future<void> _handleRecover() async {
    if (widget.onRecover == null) return;
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final bool ok = await (widget.onRecover!.call());
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Restored successfully.' : 'Failed to restore.'),
          backgroundColor: ok ? Palette.lightSuccess : Palette.lightError,
          duration: const Duration(seconds: 2),
        ),
      );
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Palette.lightError,
          duration: const Duration(seconds: 2),
        ),
      );
      await _fetchData();
    }
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
                            AppBarSearch(),
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
            onPressed: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Navigator.pop(context);
              }
            },
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    
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
      padding: EdgeInsets.all(
        isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0)
      ),
      child: isMobile 
          ? _buildMobileStatsLayout(isDark)
          : _buildDesktopStatsLayout(isDark),
    );
  }

  Widget _buildMobileStatsLayout(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    
    // For very small screens, use a more compact layout with proper separators
    if (isSmallMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  'Total Records',
                  totalItems,
                  isDark ? Palette.darkText : Palette.lightText,
                  isDark,
                ),
              ),
              Container(
                height: 30.0,
                width: 1.0,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: isDark ? Palette.darkDivider : Palette.lightDivider,
                  borderRadius: BorderRadius.circular(0.5),
                ),
              ),
              Expanded(
                child: _buildCompactMetric(
                  'Page',
                  '$currentPage/$totalPages',
                  Palette.lightPrimary,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: isDark ? Palette.darkDivider : Palette.lightDivider,
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
          const SizedBox(height: 16.0),
          _buildCompactMetric(
            'Status',
            hasError ? 'Error' : (isLoading ? 'Loading' : 'Active'),
            hasError 
                ? Palette.lightError 
                : (isLoading ? Palette.lightWarning : Palette.lightSuccess),
            isDark,
          ),
        ],
      );
    }
    
    // For regular mobile screens, use vertical layout with proper separators
    return Column(
      children: [
        _buildCompactMetric(
          'Total Records',
          totalItems,
          isDark ? Palette.darkText : Palette.lightText,
          isDark,
        ),
        const SizedBox(height: 20.0),
        Container(
          height: 1.0,
          decoration: BoxDecoration(
            color: isDark ? Palette.darkDivider : Palette.lightDivider,
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                'Current Page',
                '$currentPage of $totalPages',
                Palette.lightPrimary,
                isDark,
              ),
            ),
            Container(
              height: 30.0,
              width: 1.0,
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkDivider : Palette.lightDivider,
                borderRadius: BorderRadius.circular(0.5),
              ),
            ),
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
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStatsLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactMetric(
            'Total Records',
            totalItems,
            isDark ? Palette.darkText : Palette.lightText,
            isDark,
          ),
        ),
        _buildVerticalSeparator(isDark),
        Expanded(
          child: _buildCompactMetric(
            'Current Page',
            '$currentPage of $totalPages',
            Palette.lightPrimary,
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
            'Items/Page',
            itemsPerPage,
            isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow(bool isDark) {
    final bool hasSelection = _selectedGlobalIndex != null;
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
        
        // Right-side actions for archives (Recover, Download PDF, Delete)
        Row(
          children: [
            if (widget.onArchive != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: OutlinedButton.icon(
                  onPressed: isLoading || (widget.enableRowSelection && !hasSelection) ? null : _handleArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Palette.darkText : Palette.lightText,
                    side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                ),
              ),
            if (widget.onRecover != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton.icon(
                  onPressed: isLoading || (widget.enableRowSelection && !hasSelection) ? null : _handleRecover,
                  icon: const Icon(Icons.restore),
                  label: const Text('Recover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                ),
              ),
            if (widget.onDownloadPdf != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: OutlinedButton.icon(
                  onPressed: isLoading || (widget.enableRowSelection && !hasSelection) ? null : widget.onDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Palette.darkText : Palette.lightText,
                    side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                ),
              ),
            if (widget.onDelete != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton.icon(
                  onPressed: isLoading || (widget.enableRowSelection && !hasSelection) ? null : _showDeleteConfirmation,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.lightError,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                ),
              ),
            if (widget.customActions != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: widget.customActions!,
              ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation() async {
    _deleteAlsoDownloadPdf = false;
    final bool isMobile = ResponsiveHelper.isMobile(context);

    if (!isMobile) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          final bool localIsDark = Provider.of<ThemeProvider>(context).isDarkMode;
          return AlertDialog(
            backgroundColor: localIsDark ? Palette.darkCard : Palette.lightCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            title: Text(
              'Delete ${widget.tableName}?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: localIsDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action cannot be undone. Are you sure you want to continue?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: localIsDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    CheckboxListTile(
                      value: _deleteAlsoDownloadPdf,
                      onChanged: (v) {
                        setStateDialog(() {
                          _deleteAlsoDownloadPdf = v ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Also download full information as PDF'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Palette.lightError),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (confirmed == true) {
        widget.onDelete?.call(_deleteAlsoDownloadPdf);
      }
    } else {
      // Mobile: bottom sheet
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final bool localIsDark = Provider.of<ThemeProvider>(context).isDarkMode;
          return Container(
            decoration: BoxDecoration(
              color: localIsDark ? Palette.darkCard : Palette.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: StatefulBuilder(
              builder: (context, setStateSheet) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: localIsDark ? Palette.darkDivider : Palette.lightDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.delete_outline, color: Palette.lightError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Delete ${widget.tableName}?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: localIsDark ? Palette.darkText : Palette.lightText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: localIsDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _deleteAlsoDownloadPdf,
                      onChanged: (v) {
                        setStateSheet(() {
                          _deleteAlsoDownloadPdf = v ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Also download full information as PDF'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onDelete?.call(_deleteAlsoDownloadPdf);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.lightError,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    }
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
    
    return Column(
      children: [
        Expanded(
          child: _buildDataTable(isDark),
        ),
        const SizedBox(height: 16.0),
        _buildPaginationWidget(isDark),
      ],
    );
  }

  Widget _buildPaginationWidget(bool isDark) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Column(
      children: [
        // Page info and items per page selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page info
              Text(
                _getPageInfoText(),
                style: TextStyle(
                  fontSize: isMobile ? 12.0 : 14.0,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Items per page selector (desktop only)
              if (!isMobile)
                _buildItemsPerPageSelector(isDark, isTablet),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        // Pagination controls
        _buildPaginationControls(isDark, isMobile, isTablet),
      ],
    );
  }

  String _getPageInfoText() {
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);
    return 'Showing $startItem-$endItem of $totalItems items';
  }

  Widget _buildItemsPerPageSelector(bool isDark, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Show:',
          style: TextStyle(
            fontSize: isTablet ? 12.0 : 14.0,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: isDark ? Palette.darkSurface.withValues(alpha: 0.5) : Palette.lightSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isDark ? Palette.darkBorder.withValues(alpha: 0.3) : Palette.lightBorder.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: DropdownButton<int>(
            value: itemsPerPage,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 14.0,
              color: isDark ? Palette.darkText : Palette.lightText,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: isDark ? Palette.darkCard : Palette.lightCard,
            onChanged: (int? newValue) {
              if (newValue != null) {
                _onItemsPerPageChanged(newValue);
              }
            },
            items: const [10, 25, 50, 100].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 14.0,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          'per page',
          style: TextStyle(
            fontSize: isTablet ? 12.0 : 14.0,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDark, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page button
          _buildPageButton(
            icon: Icons.first_page,
            onPressed: currentPage > 1 ? () => _onPageChanged(1) : null,
            isDark: isDark,
            isMobile: isMobile,
            tooltip: 'First page',
          ),
          const SizedBox(width: 6.0),
          
          // Previous page button
          _buildPageButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 1 ? () => _onPageChanged(currentPage - 1) : null,
            isDark: isDark,
            isMobile: isMobile,
            tooltip: 'Previous page',
          ),
          const SizedBox(width: 12.0),
          
          // Page numbers
          if (!isMobile) _buildPageNumbers(isDark, isTablet),
          if (isMobile) _buildMobilePageInfo(isDark),
          
          const SizedBox(width: 12.0),
          
          // Next page button
          _buildPageButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < totalPages ? () => _onPageChanged(currentPage + 1) : null,
            isDark: isDark,
            isMobile: isMobile,
            tooltip: 'Next page',
          ),
          const SizedBox(width: 6.0),
          
          // Last page button
          _buildPageButton(
            icon: Icons.last_page,
            onPressed: currentPage < totalPages ? () => _onPageChanged(totalPages) : null,
            isDark: isDark,
            isMobile: isMobile,
            tooltip: 'Last page',
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
    required bool isMobile,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onPressed,
          child: Container(
            width: isMobile ? 36.0 : 40.0,
            height: isMobile ? 36.0 : 40.0,
            decoration: BoxDecoration(
              color: onPressed != null
                  ? (isDark ? Palette.darkSurface.withValues(alpha: 0.6) : Palette.lightSurface.withValues(alpha: 0.6))
                  : (isDark ? Palette.darkSurface.withValues(alpha: 0.2) : Palette.lightSurface.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8.0),
              border: onPressed != null
                  ? Border.all(
                      color: isDark ? Palette.darkBorder.withValues(alpha: 0.4) : Palette.lightBorder.withValues(alpha: 0.4),
                      width: 1.0,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: isMobile ? 18.0 : 20.0,
              color: onPressed != null
                  ? (isDark ? Palette.darkText : Palette.lightText)
                  : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumbers(bool isDark, bool isTablet) {
    final List<Widget> pageNumbers = [];
    final int maxVisiblePages = isTablet ? 5 : 7;
    
    int startPage = (currentPage - (maxVisiblePages ~/ 2)).clamp(1, totalPages);
    int endPage = (startPage + maxVisiblePages - 1).clamp(1, totalPages);
    
    // Adjust start if we're near the end
    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = (endPage - maxVisiblePages + 1).clamp(1, totalPages);
    }
    
    // Add first page and ellipsis if needed
    if (startPage > 1) {
      pageNumbers.add(_buildPageNumber(1, isDark, isTablet));
      if (startPage > 2) {
        pageNumbers.add(_buildEllipsis(isDark));
      }
    }
    
    // Add visible page numbers
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageNumber(i, isDark, isTablet));
    }
    
    // Add ellipsis and last page if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(_buildEllipsis(isDark));
      }
      pageNumbers.add(_buildPageNumber(totalPages, isDark, isTablet));
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pageNumbers,
    );
  }

  Widget _buildPageNumber(int page, bool isDark, bool isTablet) {
    final isCurrentPage = page == currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () => _onPageChanged(page),
          child: Container(
            width: isTablet ? 36.0 : 40.0,
            height: isTablet ? 36.0 : 40.0,
            decoration: BoxDecoration(
              color: isCurrentPage
                  ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                  : (isDark ? Palette.darkSurface.withValues(alpha: 0.3) : Palette.lightSurface.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8.0),
              border: isCurrentPage
                  ? null
                  : Border.all(
                      color: isDark ? Palette.darkBorder.withValues(alpha: 0.3) : Palette.lightBorder.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              page.toString(),
              style: TextStyle(
                fontSize: isTablet ? 13.0 : 14.0,
                fontWeight: isCurrentPage ? FontWeight.w700 : FontWeight.w500,
                color: isCurrentPage
                    ? Colors.white
                    : (isDark ? Palette.darkText : Palette.lightText),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 14.0,
          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildMobilePageInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkSurface.withValues(alpha: 0.6) : Palette.lightSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder.withValues(alpha: 0.4) : Palette.lightBorder.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Text(
        '$currentPage / $totalPages',
        style: TextStyle(
          fontSize: 13.0,
          color: isDark ? Palette.darkText : Palette.lightText,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        child: Scrollbar(
          controller: _tableHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _tableHorizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
              columnSpacing: 24.0,
              horizontalMargin: 16.0,
              headingRowHeight: 56.0,
              dataRowMinHeight: 48.0,
              dataRowMaxHeight: 64.0,
              showCheckboxColumn: widget.enableRowSelection,
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
              rows: _buildSelectableRows(isDark),
            ),
          ),
        ),
      ),
    ),
    );
  }

  List<DataRow> _buildSelectableRows(bool isDark) {
    final List<DataRow> builtRows = widget.rowBuilder(paginatedData).toList();
    final int pageStartIndex = (currentPage - 1) * itemsPerPage;
    return List<DataRow>.generate(builtRows.length, (int localIndex) {
      final DataRow src = builtRows[localIndex];
      final int globalIndex = pageStartIndex + localIndex;
      final bool isSelected = widget.enableRowSelection && (_selectedGlobalIndex == globalIndex);
      return DataRow(
        selected: isSelected,
        onSelectChanged: widget.enableRowSelection
            ? (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGlobalIndex = globalIndex;
                  } else {
                    _selectedGlobalIndex = null;
                  }
                });
                if (widget.onSelectionChanged != null) {
                  widget.onSelectionChanged!.call(
                    _selectedGlobalIndex != null && _selectedGlobalIndex! >= 0 && _selectedGlobalIndex! < tableData.length
                        ? tableData[_selectedGlobalIndex!]
                        : null,
                  );
                }
              }
            : null,
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? Palette.darkPrimary.withValues(alpha: 0.15)
                : Palette.lightPrimary.withValues(alpha: 0.15);
          }
          if (states.contains(WidgetState.hovered)) {
            return isDark
                ? Palette.darkBorder.withValues(alpha: 0.3)
                : Palette.lightBorder.withValues(alpha: 0.3);
          }
          return null;
        }),
        cells: src.cells.map((cell) {
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
    });
  }

  Widget _buildCompactMetric(String label, dynamic value, Color valueColor, bool isDark) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0),
            letterSpacing: isSmallMobile ? 0.4 : 0.6,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isSmallMobile ? 4.0 : 8.0),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isSmallMobile ? 16.0 : (isMobile ? 18.0 : 22.0),
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
