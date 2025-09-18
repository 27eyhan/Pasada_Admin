# Table Preview Widget System

This document explains how to use the new centralized table preview system that provides a consistent, responsive, and efficient way to display database tables throughout the application.

## Overview

The table preview system consists of two main components:

1. **`TablePreviewWidget`** - The main reusable widget that handles all table display logic
2. **`TablePreviewHelper`** - Helper class with pre-configured table types for common use cases

## Features

- ✅ **Consistent Design**: Follows the application's design language with proper theming
- ✅ **Loading States**: Beautiful animated loading indicators with progress feedback
- ✅ **Error Handling**: Graceful error states with retry functionality
- ✅ **Empty States**: Informative empty state when no data is available
- ✅ **Responsive Design**: Adapts to different screen sizes automatically
- ✅ **Navigation**: Built-in back button and proper navigation handling
- ✅ **Refresh Functionality**: Manual refresh with visual feedback
- ✅ **Filter Support**: Optional filter button integration
- ✅ **Custom Actions**: Support for additional action buttons
- ✅ **Performance**: Efficient data handling and rendering

## Quick Start

### Using Pre-configured Tables

The easiest way to use the table preview system is with the helper methods:

```dart
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';

// Create an admin table
Widget adminTable = TablePreviewHelper.createAdminTable(
  dataFetcher: () async {
    final data = await supabase.from('adminTable').select('*');
    return (data as List).cast<Map<String, dynamic>>();
  },
  onRefresh: () {
    // Custom refresh logic
  },
);

// Create a driver table with filter support
Widget driverTable = TablePreviewHelper.createDriverTable(
  dataFetcher: () async {
    final data = await supabase.from('driverTable').select('*');
    return (data as List).cast<Map<String, dynamic>>();
  },
  onFilterPressed: () {
    // Show filter dialog
  },
);
```

### Available Pre-configured Tables

- `createAdminTable()` - Administrator accounts
- `createDriverTable()` - Driver accounts (with filter support)
- `createPassengerTable()` - Passenger information
- `createVehicleTable()` - Fleet vehicles
- `createRouteTable()` - Transportation routes
- `createBookingsTable()` - Ride bookings
- `createDriverReviewsTable()` - Driver ratings
- `createDriverArchivesTable()` - Historical driver data

## Custom Table Implementation

For tables that don't fit the pre-configured patterns, you can create custom implementations:

```dart
import 'package:pasada_admin_application/widgets/table_preview_widget.dart';

Widget customTable = TablePreviewWidget(
  tableName: 'Custom Table',
  tableDescription: 'Description of your custom table',
  tableIcon: Icons.table_chart,
  tableColor: Palette.lightPrimary,
  dataFetcher: () async {
    // Your data fetching logic
    final data = await supabase.from('yourTable').select('*');
    return (data as List).cast<Map<String, dynamic>>();
  },
  columns: const [
    DataColumn(label: Text('Column 1')),
    DataColumn(label: Text('Column 2')),
    DataColumn(label: Text('Column 3')),
  ],
  rowBuilder: (data) => data.map((item) {
    return DataRow(
      cells: [
        DataCell(Text(item['field1']?.toString() ?? 'N/A')),
        DataCell(Text(item['field2']?.toString() ?? 'N/A')),
        DataCell(Text(item['field3']?.toString() ?? 'N/A')),
      ],
    );
  }).toList(),
  showFilterButton: true,
  onFilterPressed: () {
    // Your filter logic
  },
  customActions: Row(
    children: [
      IconButton(
        icon: Icon(Icons.add),
        onPressed: () {
          // Add new record
        },
      ),
      IconButton(
        icon: Icon(Icons.download),
        onPressed: () {
          // Export data
        },
      ),
    ],
  ),
);
```

## Parameters

### TablePreviewWidget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tableName` | String | ✅ | Display name of the table |
| `tableDescription` | String | ✅ | Description shown in header |
| `tableIcon` | IconData | ✅ | Icon displayed in header |
| `tableColor` | Color | ✅ | Primary color for the table theme |
| `dataFetcher` | Function | ✅ | Async function that returns table data |
| `columns` | List<DataColumn> | ✅ | Column definitions for the table |
| `rowBuilder` | Function | ✅ | Function that builds rows from data |
| `onRefresh` | VoidCallback | ❌ | Called when refresh button is pressed |
| `refreshInterval` | Duration | ❌ | Auto-refresh interval (not implemented yet) |
| `showFilterButton` | bool | ❌ | Whether to show filter button (default: false) |
| `onFilterPressed` | VoidCallback | ❌ | Called when filter button is pressed |
| `customActions` | Widget | ❌ | Additional action buttons in header |

## Design System Integration

The table preview widget automatically integrates with the application's design system:

- **Theming**: Supports both light and dark themes via `ThemeProvider`
- **Colors**: Uses the `Palette` color system
- **Typography**: Uses Inter font family with consistent sizing
- **Spacing**: Follows the application's spacing guidelines
- **Shadows**: Consistent shadow and border styling

## Navigation

The widget includes built-in navigation:

- **Back Button**: Styled consistently with the application's back button design
- **Navigation Bar**: Maintains the sidebar drawer and app bar
- **Page Replacement**: Replaces the current page while keeping navigation structure

## Loading States

The widget provides three loading states:

1. **Loading**: Animated progress indicator with scaling animation
2. **Error**: Error icon with retry button and error message
3. **Empty**: Informative empty state when no data is available

## Performance Considerations

- **Efficient Rendering**: Uses `SingleChildScrollView` with horizontal scrolling for large tables
- **Memory Management**: Proper disposal of animation controllers
- **Data Handling**: Efficient data fetching with proper error handling
- **Responsive Design**: Adapts to different screen sizes without performance issues

## Migration Guide

To migrate existing table screens to use the new system:

1. **Replace imports**: Remove old table screen imports, add new widget imports
2. **Update navigation**: Replace `Navigator.push` calls with the new helper methods
3. **Remove custom styling**: The new widget handles all styling automatically
4. **Update data fetching**: Ensure your data fetcher returns the correct format
5. **Test functionality**: Verify that all features work as expected

## Example Migration

### Before (Old Admin Table)
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AdminTableScreen()),
);
```

### After (New Admin Table)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TablePreviewHelper.createAdminTable(
      dataFetcher: () async {
        final data = await supabase.from('adminTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
    ),
  ),
);
```

## Best Practices

1. **Use Helper Methods**: Prefer the helper methods for common table types
2. **Consistent Naming**: Use consistent table names and descriptions
3. **Error Handling**: Always handle errors in your data fetcher
4. **Performance**: Avoid heavy computations in the data fetcher
5. **Accessibility**: Ensure your data is properly formatted for screen readers

## Troubleshooting

### Common Issues

1. **Data Format**: Ensure your data fetcher returns `List<Map<String, dynamic>>`
2. **Column Mismatch**: Make sure your row builder matches your column definitions
3. **Theme Issues**: The widget automatically handles theming, no manual intervention needed
4. **Navigation Issues**: The back button is built-in, no additional navigation code needed

### Debug Tips

- Check the console for data fetching errors
- Verify that your Supabase queries return the expected format
- Ensure all required parameters are provided
- Test with both light and dark themes
