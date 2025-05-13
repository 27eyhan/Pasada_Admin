import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class DriverFilterDialog extends StatefulWidget {
  final Set<String> selectedStatuses;
  final String? selectedVehicleId;
  final String sortOption;
  
  const DriverFilterDialog({
    Key? key,
    required this.selectedStatuses,
    this.selectedVehicleId,
    required this.sortOption,
  }) : super(key: key);

  @override
  _DriverFilterDialogState createState() => _DriverFilterDialogState();
}

class _DriverFilterDialogState extends State<DriverFilterDialog> {
  late Set<String> _selectedStatuses;
  late TextEditingController _vehicleIdController;
  late String _sortOption;
  
  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.selectedStatuses);
    _vehicleIdController = TextEditingController(text: widget.selectedVehicleId ?? '');
    _sortOption = widget.sortOption;
  }
  
  @override
  void dispose() {
    _vehicleIdController.dispose();
    super.dispose();
  }

  Widget _buildStatusCheckbox(String status) {
    return CheckboxListTile(
      title: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16.0,
          color: Palette.blackColor,
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
      activeColor: Palette.blackColor,
      checkColor: Palette.whiteColor,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16.0,
          color: Palette.blackColor,
        ),
      ),
      value: value,
      groupValue: _sortOption,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _sortOption = newValue;
          });
        }
      },
      activeColor: Palette.blackColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.6;
    final double dialogWidth = screenWidth * 0.5;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.blackColor, width: 1),
      ),
      elevation: 8.0,
      backgroundColor: Palette.whiteColor,
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
                    Icon(Icons.filter_list, color: Palette.blackColor, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Filter Options",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Palette.blackColor,
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
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Palette.blackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: Palette.blackColor.withAlpha(50), thickness: 1.5),
            const SizedBox(height: 24.0),
            
            // Status section
            Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              margin: EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  _buildStatusCheckbox('Online'),
                  _buildStatusCheckbox('Offline'),
                ],
              ),
            ),
            
            // Vehicle ID section
            Text(
              'Vehicle ID',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _vehicleIdController,
              decoration: InputDecoration(
                hintText: 'Enter Vehicle ID',
                hintStyle: TextStyle(
                  color: Palette.blackColor.withAlpha(128),
                  fontSize: 14.0,
                  fontFamily: 'Inter',
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Palette.blackColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Sort Options
            Text(
              'Sort By',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              margin: EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  _buildSortOption('Name (A-Z)', 'alphabetical'),
                  _buildSortOption('Driver ID', 'numeric'),
                ],
              ),
            ),
            
            const SizedBox(height: 12.0),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatuses.clear();
                      _vehicleIdController.clear();
                      _sortOption = 'numeric'; // Reset to default sort
                    });
                  },
                  icon: Icon(Icons.clear_all, color: Palette.redColor, size: 20),
                  label: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Palette.redColor,
                      fontSize: 14.0,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Palette.blackColor,
                          fontSize: 14.0,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.0),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.blackColor,
                        foregroundColor: Palette.whiteColor,
                        elevation: 4.0,
                        shadowColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      ),
                      onPressed: () {
                        String? vehicleId = _vehicleIdController.text.isNotEmpty 
                            ? _vehicleIdController.text 
                            : null;
                        Navigator.pop(
                          context, 
                          {
                            'selectedStatuses': _selectedStatuses,
                            'selectedVehicleId': vehicleId,
                            'sortOption': _sortOption,
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
                          color: Palette.whiteColor,
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
  }
} 