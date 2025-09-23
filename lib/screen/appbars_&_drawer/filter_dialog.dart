import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';

class FilterDialog extends StatefulWidget {
  final Set<String> selectedStatuses;
  final String? selectedRouteId;

  const FilterDialog({
    super.key,
    required this.selectedStatuses,
    this.selectedRouteId,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<String> _selectedStatuses;
  late TextEditingController _routeIdController;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.selectedStatuses);
    _routeIdController =
        TextEditingController(text: widget.selectedRouteId ?? '');
  }

  @override
  void dispose() {
    _routeIdController.dispose();
    super.dispose();
  }

  Widget _buildStatusCheckbox(String status, bool isDark) {
    return CheckboxListTile(
      title: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16.0,
          color: isDark ? Palette.darkText : Palette.lightText,
        ),
      ),
      value: _selectedStatuses.contains(status),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedStatuses.add(status);
          } else {
            _selectedStatuses.remove(status);
          }
        });
      },
      activeColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.6;
    final double dialogWidth = screenWidth * 0.5;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1),
          ),
          elevation: 8.0,
          backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: isDark ? Palette.darkText : Palette.lightText, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Filter Options",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Palette.darkText : Palette.lightText,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Palette.darkCard : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, thickness: 1.5),
            const SizedBox(height: 24.0),

            // Status section
            Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Palette.darkCard : Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: isDark ? Palette.darkBorder : Colors.grey[300]!),
              ),
              margin: EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  _buildStatusCheckbox('Online', isDark),
                  _buildStatusCheckbox('Idling', isDark),
                  _buildStatusCheckbox('Driving', isDark),
                  _buildStatusCheckbox('Offline', isDark),
                ],
              ),
            ),

            // Route ID section
            Text(
              'Route ID',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _routeIdController,
              style: TextStyle(
                color: isDark ? Palette.darkText : Palette.lightText,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Enter Route ID',
                hintStyle: TextStyle(
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  fontSize: 14.0,
                  fontFamily: 'Inter',
                ),
                filled: true,
                fillColor: isDark ? Palette.darkCard : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: isDark ? Palette.darkBorder : Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: isDark ? Palette.darkBorder : Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: isDark ? Palette.darkPrimary : Palette.lightPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 32.0),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatuses.clear();
                      _routeIdController.clear();
                    });
                  },
                  icon:
                      Icon(Icons.clear_all, color: Palette.lightError, size: 20),
                  label: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Palette.lightError,
                      fontSize: 14.0,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Palette.darkText : Palette.lightText,
                          fontSize: 14.0,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.0),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                        foregroundColor: Colors.white,
                        elevation: 4.0,
                        shadowColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                      ),
                      onPressed: () {
                        String? routeId = _routeIdController.text.isNotEmpty
                            ? _routeIdController.text
                            : null;
                        Navigator.pop(
                          context,
                          {
                            'selectedStatuses': _selectedStatuses,
                            'selectedRouteId': routeId,
                          },
                        );
                      },
                      icon: Icon(Icons.check, size: 20),
                      label: Text(
                        'Apply',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
