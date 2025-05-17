import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/driver_filter_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/add_driver_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/driver_delete_handler.dart';
import 'package:flutter/services.dart';

class DriverTableScreen extends StatefulWidget {
  const DriverTableScreen({Key? key}) : super(key: key);

  @override
  _DriverTableScreenState createState() => _DriverTableScreenState();
}

class _DriverTableScreenState extends State<DriverTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverData = [];
  List<Map<String, dynamic>> filteredDriverData = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  int? _selectedRowIndex;
  String? _pendingAction;
  
  // Filter state
  Set<String> selectedStatuses = {};
  String? selectedVehicleId;
  String sortOption = 'numeric'; // Default sorting

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       if (mounted) {
          fetchDriverData();
       }
    });
     // Debug
  }

  @override
  void initState() {
    super.initState();
    fetchDriverData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _showFilterDialog() async {
    _refreshTimer?.cancel(); // Pause timer during filtering
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return DriverFilterDialog(
          selectedStatuses: selectedStatuses,
          selectedVehicleId: selectedVehicleId,
          sortOption: sortOption,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedStatuses = result['selectedStatuses'] as Set<String>;
        selectedVehicleId = result['selectedVehicleId'] as String?;
        sortOption = result['sortOption'] as String;
        _applyFilters();
      });
    }
    
    _startRefreshTimer(); // Resume timer
  }
  
  void _applyFilters() {
    setState(() {
      if (selectedStatuses.isEmpty && selectedVehicleId == null) {
        // No filters applied, show all data
        filteredDriverData = List.from(driverData);
      } else {
        filteredDriverData = driverData.where((driver) {
          // Filter by status
          bool statusMatch = true;
          if (selectedStatuses.isNotEmpty) {
            final status = driver["driving_status"]?.toString() ?? "Offline";
            
            if (selectedStatuses.contains('Online')) {
              // For Online, match any of these statuses
              bool isActive = status.toLowerCase() == "driving" || 
                              status.toLowerCase() == "online" || 
                              status.toLowerCase() == "idling" || 
                              status.toLowerCase() == "active";
              
              if (selectedStatuses.contains('Offline')) {
                // If both Online and Offline are selected, show all
                statusMatch = true;
              } else {
                // Only Online is selected
                statusMatch = isActive;
              }
            } else if (selectedStatuses.contains('Offline')) {
              // Only Offline is selected
              bool isOffline = status.toLowerCase() == "offline" ||
                               status.toLowerCase() == "";
              statusMatch = isOffline;
            }
          }
          
          // Filter by vehicle ID
          bool vehicleMatch = selectedVehicleId == null || 
              driver['vehicle_id']?.toString() == selectedVehicleId;

          return statusMatch && vehicleMatch;
        }).toList();
      }
      
      // Apply sorting
      if (sortOption == 'alphabetical') {
        filteredDriverData.sort((a, b) {
          final nameA = a['full_name']?.toString() ?? '';
          final nameB = b['full_name']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
      } else { // numeric sorting is default
        filteredDriverData.sort((a, b) {
          final numA = int.tryParse(a['driver_id']?.toString() ?? '0') ?? 0;
          final numB = int.tryParse(b['driver_id']?.toString() ?? '0') ?? 0;
          return numA.compareTo(numB);
        });
      }
    });
  }

  Future<void> fetchDriverData() async {
    // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from 'driverTable'
      final data = await supabase.from('driverTable').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
       if (mounted) { // Check if the widget is still mounted
        setState(() {
          driverData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
          
          // Apply any existing filters
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          isLoading = false;
          driverData = [];
          filteredDriverData = [];
        });
      }
    }
  }

  // --- Action Handlers ---
  void _handleAddDriver() async {
    try {
       await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddDriverDialog(
            supabase: supabase,
            onDriverAdded: fetchDriverData,
          );
        },
      );
    } finally {
       // Debug
      _startRefreshTimer();
    }
  }

  void _handleEditDriver(Map<String, dynamic> selectedDriverData) async {
    // Create controllers for editable fields
    final TextEditingController fullNameController = TextEditingController(text: selectedDriverData['full_name'] ?? '');
    final TextEditingController driverNumberController = TextEditingController(text: selectedDriverData['driver_number'] ?? '');
    final TextEditingController vehicleIdController = TextEditingController(text: selectedDriverData['vehicle_id']?.toString() ?? '');
    final TextEditingController licenseNumberController = TextEditingController(text: selectedDriverData['driver_license_number'] ?? '');
    
    final driverId = selectedDriverData['driver_id'];
    final driverStatus = selectedDriverData['driving_status'] ?? 'N/A';
    bool isLoading = false;
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(color: Palette.orangeColor, width: 2),
                ),
                backgroundColor: Palette.whiteColor,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Icon and title
                        Icon(Icons.edit_note, color: Palette.orangeColor, size: 48),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            'Edit Driver Information',
                            style: TextStyle(
                              fontSize: 22.0,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: Palette.orangeColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Non-editable fields
                        _buildInfoRow('Driver ID:', driverId.toString()),
                        _buildInfoRow('Status:', driverStatus),
                        SizedBox(height: 16),
                        
                        // Editable form fields
                        _buildFormField(
                          context: context,
                          controller: fullNameController,
                          label: 'Name',
                          icon: Icons.person_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter driver name' : null,
                        ),
                        _buildFormField(
                          context: context,
                          controller: licenseNumberController,
                          label: 'License Number',
                          icon: Icons.credit_card,
                          hintText: 'AXX-XX-XXXXXX',
                          inputFormatters: [
                            LicenseNumberFormatter(),
                            LengthLimitingTextInputFormatter(12), // A00-00-000000 = 12 chars
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter driver license number';
                            }
                            
                            // Regex pattern for Philippine license format "A00-00-000000"
                            RegExp licenseFormat = RegExp(r'^[A-Z]\d{2}-\d{2}-\d{6}$');
                            if (!licenseFormat.hasMatch(value)) {
                              return 'Format should be A00-00-000000 (letter-numbers)';
                            }
                            
                            return null;
                          },
                        ),
                        _buildFormField(
                          context: context,
                          controller: driverNumberController,
                          label: 'Driver Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter driver number' : null,
                        ),
                        _buildFormField(
                          context: context,
                          controller: vehicleIdController,
                          label: 'Vehicle ID',
                          icon: Icons.directions_car_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vehicle ID';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16.0),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                elevation: 3,
                                minimumSize: Size(140, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),
                              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel, size: 20),
                                  SizedBox(width: 8),
                                  Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.orangeColor,
                                foregroundColor: Palette.whiteColor,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                elevation: 3,
                                minimumSize: Size(140, 50),
                                shadowColor: Palette.orangeColor.withAlpha(128),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onPressed: isLoading ? null : () async {
                                // Check if data has changed
                                if (fullNameController.text == selectedDriverData['full_name'] &&
                                    driverNumberController.text == selectedDriverData['driver_number'] &&
                                    vehicleIdController.text == selectedDriverData['vehicle_id']?.toString() &&
                                    licenseNumberController.text == selectedDriverData['driver_license_number']) {
                                  _showInfoSnackBar('No changes were made');
                                  Navigator.of(context).pop();
                                  return;
                                }
                                
                                setState(() {
                                  isLoading = true;
                                });
                                
                                try {
                                  // Check for duplicate vehicle ID
                                  if (vehicleIdController.text.isNotEmpty) {
                                    final duplicateVehicleId = await _checkForDuplicateData(
                                      'vehicle_id', 
                                      vehicleIdController.text,
                                      driverId.toString(),
                                    );
                                    
                                    if (duplicateVehicleId) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      _showInfoSnackBar('Vehicle ID is already assigned to another driver');
                                      return;
                                    }
                                  }
                                  
                                  // Create updated driver data with dynamic typing
                                  final Map<String, dynamic> updatedDriver = {
                                    'full_name': fullNameController.text,
                                    'driver_number': driverNumberController.text,
                                    'driver_license_number': licenseNumberController.text,
                                  };
                                  
                                  // Only include vehicle_id if it's not empty
                                  if (vehicleIdController.text.isNotEmpty) {
                                    updatedDriver['vehicle_id'] = int.parse(vehicleIdController.text);
                                  }
                                  
                                  // Update the driver in the database
                                  await supabase
                                      .from('driverTable')
                                      .update(updatedDriver)
                                      .eq('driver_id', driverId);
                                  
                                  Navigator.of(context).pop(); // Close dialog
                                  _showInfoSnackBar('Driver information updated successfully');
                                  fetchDriverData(); // Refresh table data
                                  
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  _showInfoSnackBar('Error updating driver: ${e.toString()}');
                                }
                              },
                              child: isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          );
        },
      );
    } finally {
      // Clean up controllers
      fullNameController.dispose();
      driverNumberController.dispose();
      vehicleIdController.dispose();
      licenseNumberController.dispose();
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleDeleteDriver(Map<String, dynamic> selectedDriverData) async {
    await DriverDeleteHandler.handleDeleteDriver(
      context,
      selectedDriverData,
      fetchDriverData,
      _showInfoSnackBar,
    );
    _startRefreshTimer();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Helper method to build form fields
  Widget _buildFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required String? Function(String?) validator,
    String? hintText,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: Icon(icon, color: Palette.orangeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Palette.orangeColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        inputFormatters: inputFormatters,
      ),
    );
  }
  
  // Check if data already exists for another driver
  Future<bool> _checkForDuplicateData(String field, String value, String currentDriverId) async {
    if (value.isEmpty) return false;
    
    try {
      final response = await supabase
          .from('driverTable')
          .select('driver_id')
          .eq(field, value)
          .neq('driver_id', currentDriverId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
     // Determine if Continue button should be enabled
    final bool isRowSelected = _selectedRowIndex != null;
    final Map<String, dynamic>? selectedData = isRowSelected && _selectedRowIndex! < filteredDriverData.length 
      ? filteredDriverData[_selectedRowIndex!] 
      : null;

    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(onFilterPressed: _showFilterDialog),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          // Main content: loading indicator or table display.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : driverData.isEmpty
                    ? const Center(child: Text("No data found."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Palette.whiteColor,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Palette.blackColor.withValues(alpha: 128),
                              width: 1,
                            ),
                          ),
                          child: DataTable(
                            columnSpacing: 90.0, // Reduce column spacing
                            horizontalMargin: 12.0, // Reduce horizontal margin
                            headingRowHeight: 50.0, // Reduce heading row height
                            dataRowMinHeight: 40.0, // Set minimum row height
                            dataRowMaxHeight: 60.0, // Set maximum row height
                            showCheckboxColumn: false, // Remove checkbox column 
                            columns: const [
                              DataColumn(label: Text('Driver ID', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('License No.', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Number', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Vehicle ID', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Last Online', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredDriverData.asMap().entries.map((entry) { // Use filteredDriverData instead of driverData
                              final int index = entry.key;
                              final Map<String, dynamic> driver = entry.value;
                              final bool allowSelection = _pendingAction != null;

                              return DataRow(
                                selected: allowSelection && (_selectedRowIndex == index),
                                onSelectChanged: allowSelection
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
                                        // No need for warning logic with radio buttons
                                        _selectedRowIndex = index;
                                      } else {
                                        if (_selectedRowIndex == index) {
                                          _selectedRowIndex = null;
                                        }
                                      }
                                    });
                                  }
                                  : null,
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        if (allowSelection)
                                          Radio<int>(
                                            value: index,
                                            groupValue: _selectedRowIndex,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _selectedRowIndex = value;
                                              });
                                            },
                                          ),
                                        SizedBox(width: 8),
                                        Text(driver['driver_id'].toString(), style: TextStyle(fontSize: 12.0)),
                                      ],
                                    )
                                  ),
                                  DataCell(Text(driver['full_name'] ?? 'Unknown', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['driver_license_number'] ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['driver_number']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['vehicle_id']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['driving_status']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['last_online']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button at top-left
          Positioned(
            top: 26.0,
            left: 26.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: IconButton(
                  iconSize: 28.0,
                  icon: const Icon(Icons.arrow_back, color: Palette.blackColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          // Positioned Action Button (Top Right)
          Positioned(
            top: 26.0,
            right: 26.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                  color: Palette.whiteColor,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.edit, color: Palette.blackColor),
                  tooltip: 'Actions',
                  color: Palette.whiteColor,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8),
                  onSelected: (String value) {
                    _refreshTimer?.cancel(); // Cancel timer immediately
                    // Debug
                    switch (value) {
                      case 'add':
                        _handleAddDriver();
                        break;
                      case 'edit':
                      case 'delete':
                        setState(() {
                          _pendingAction = value;
                          _selectedRowIndex = null; // Ensure no row is selected initially for the new action
                        });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Add Driver'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Selected'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Selected'),
                    ),
                  ],
                ),
              ),
            ),
          ),
           // Confirmation Buttons (Bottom Center)
          Positioned(
            bottom: 16.0,
            left: 0,
            right: 0,
            child: Center(
              child: Visibility(
                visible: _pendingAction != null,
                child: Container(
                   padding: const EdgeInsets.all(8.0),
                   decoration: BoxDecoration(
                      color: Palette.whiteColor,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [ BoxShadow(color: Colors.grey.withValues(alpha: 128), spreadRadius: 2, blurRadius: 5) ],
                   ),
                   child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          // Debug
                          _refreshTimer?.cancel(); // Cancel just in case
                           _startRefreshTimer(); // Restart timer
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? Colors.green : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected && selectedData != null
                            ? () {
                                _refreshTimer?.cancel(); // Cancel timer before action
                                // Debug

                                if (_pendingAction == 'edit') {
                                  _handleEditDriver(selectedData);
                                } else if (_pendingAction == 'delete') {
                                  _handleDeleteDriver(selectedData);
                                }
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                              }
                            : null,
                        child: Text('Continue ${_pendingAction == 'edit' ? 'Edit' : (_pendingAction == 'delete' ? 'Delete' : _pendingAction ?? '')}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
