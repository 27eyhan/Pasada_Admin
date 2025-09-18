import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';

class AdminTableScreenNew extends StatelessWidget {
  const AdminTableScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    return TablePreviewHelper.createAdminTable(
      dataFetcher: () async {
        final data = await supabase.from('adminTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        // Custom refresh logic can be added here
        print('Admin table refreshed');
      },
    );
  }
}
