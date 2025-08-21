import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DataTables extends StatefulWidget {
  @override
  _DataTablesState createState() => _DataTablesState();
}

class _DataTablesState extends State<DataTables> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      body: Row(
        children: [
          // Fixed width sidebar drawer
          Container(
            width: 280, // Fixed width for the sidebar
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
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            margin: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Palette.whiteColor,
                              border: Border.all(color: Palette.blackColor, width: 1.0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DataTable(
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Palette.blackColor,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Palette.blackColor,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Palette.blackColor,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: [],
                              ),
                            ),
                          ),
                        ),
                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
