import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DriverReviewsTableScreen extends StatefulWidget {
  const DriverReviewsTableScreen({Key? key}) : super(key: key);

  @override
  _DriverReviewsTableScreenState createState() => _DriverReviewsTableScreenState();
}

class _DriverReviewsTableScreenState extends State<DriverReviewsTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverReviewsData = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchDriverReviewsData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        fetchDriverReviewsData();
      }
    });
  }

  Future<void> fetchDriverReviewsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch driver data with their reviews and ratings
      final driversResponse = await supabase
          .from('driverTable')
          .select('driver_id, full_name, driver_license_number');

      final List<dynamic> drivers = driversResponse as List<dynamic>;
      List<Map<String, dynamic>> compiledData = [];

      for (var driver in drivers) {
        final driverId = driver['driver_id'];
        
        // Calculate average rating and collect reviews
        double averageRating = 0.0;
        List<String> reviews = [];
        int totalBookings = 0;
        
        try {
          // Fetch bookings data for this driver
          final bookingsResponse = await supabase
              .from('bookings')
              .select('rating, review')
              .eq('driver_id', driverId);

          final List<dynamic> bookings = bookingsResponse as List<dynamic>;
          totalBookings = bookings.length;
          
          if (bookings.isNotEmpty) {
            double totalRating = 0.0;
            int ratingCount = 0;
            
            for (var booking in bookings) {
              if (booking['rating'] != null) {
                totalRating += (booking['rating'] as num).toDouble();
                ratingCount++;
              }
              
              if (booking['review'] != null && booking['review'].toString().trim().isNotEmpty) {
                reviews.add(booking['review'].toString());
              }
            }
            
            if (ratingCount > 0) {
              averageRating = totalRating / ratingCount;
            }
          }
        } catch (bookingError) {
          // If bookings table doesn't exist or there's an error, continue with driver but no ratings/reviews
          print('Error fetching bookings for driver $driverId: $bookingError');
        }

        // Add driver data regardless of whether they have bookings or not
        compiledData.add({
          'driver_id': driverId,
          'full_name': driver['full_name'],
          'driver_license_number': driver['driver_license_number'],
          'average_rating': averageRating,
          'total_reviews': reviews.length,
          'reviews': reviews,
          'total_bookings': totalBookings,
        });
      }

      if (mounted) {
        setState(() {
          driverReviewsData = compiledData;
          isLoading = false;
        });
        // Debug information
        print('Loaded ${compiledData.length} drivers');
      }
    } catch (e) {
      print('Error fetching driver data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          driverReviewsData = [];
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading driver data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double remainder = rating - fullStars;
    
    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber, size: 20));
    }
    
    // Add half star if needed
    if (remainder >= 0.5) {
      stars.add(Icon(Icons.star_half, color: Colors.amber, size: 20));
    } else if (remainder > 0) {
      stars.add(Icon(Icons.star_border, color: Colors.amber, size: 20));
    }
    
    // Add empty stars to make 5 total
    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border, color: Colors.grey[300], size: 20));
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        SizedBox(width: 8),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'No ratings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: rating > 0 ? Colors.amber[700] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDriverDetails(Map<String, dynamic> driverData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Palette.orangeColor, width: 2),
          ),
          backgroundColor: Palette.whiteColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.person, color: Palette.orangeColor, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Driver Reviews & Ratings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Palette.orangeColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(color: Palette.orangeColor, thickness: 1),
                  SizedBox(height: 16),
                  
                  // Driver Info
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow('Driver ID:', driverData['driver_id'].toString()),
                        _buildInfoRow('Name:', driverData['full_name'] ?? 'N/A'),
                        _buildInfoRow('License Number:', driverData['driver_license_number'] ?? 'N/A'),
                        _buildInfoRow('Total Bookings:', driverData['total_bookings'].toString()),
                        _buildInfoRow('Total Reviews:', driverData['total_reviews'].toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Rating Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Rating',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: _buildStarRating(driverData['average_rating']),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Reviews Section
                  Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: driverData['reviews'].isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rate_review_outlined, 
                                         size: 48, color: Colors.grey[400]),
                                    SizedBox(height: 12),
                                    Text(
                                      'No reviews yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(12),
                              itemCount: driverData['reviews'].length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.format_quote, 
                                           color: Colors.grey[400], size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          driverData['reviews'][index],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          // Main content
          Center(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : driverReviewsData.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No driver data found.",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Please check if the driverTable exists in your database.",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
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
                            columnSpacing: 80.0,
                            horizontalMargin: 12.0,
                            headingRowHeight: 50.0,
                            dataRowMinHeight: 40.0,
                            dataRowMaxHeight: 60.0,
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Driver ID', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('License No.', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Avg Rating', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Total Reviews', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', 
                                style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                            ],
                            rows: driverReviewsData.asMap().entries.map((entry) {
                              final Map<String, dynamic> driver = entry.value;

                              return DataRow(
                                cells: [
                                  DataCell(Text(driver['driver_id'].toString(), 
                                    style: TextStyle(fontSize: 12.0))),
                                  DataCell(Text(driver['full_name'] ?? 'Unknown', 
                                    style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(driver['driver_license_number'] ?? 'N/A', 
                                    style: TextStyle(fontSize: 14.0))),
                                  DataCell(_buildStarRating(driver['average_rating'])),
                                  DataCell(Text(driver['total_reviews'].toString(), 
                                    style: TextStyle(fontSize: 14.0))),
                                  DataCell(
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.visibility, size: 16),
                                      label: Text('View Details'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Palette.orangeColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size(0, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      onPressed: () => _showDriverDetails(driver),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          
          // Back button
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
        ],
      ),
    );
  }
} 