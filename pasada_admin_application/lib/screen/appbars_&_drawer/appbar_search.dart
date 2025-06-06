import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/profilepopup.dart';
import 'package:pasada_admin_application/screen/settings_pages/notifpopup.dart';
import 'package:pasada_admin_application/screen/settings_pages/securitypopup.dart';
import 'package:pasada_admin_application/screen/settings_pages/updatespopup.dart';
import 'package:pasada_admin_application/services/auth_service.dart';

typedef FilterCallback = void Function();

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final FilterCallback? onFilterPressed;

  AppBarSearch({Key? key, this.onFilterPressed})
      : preferredSize = const Size.fromHeight(70.0),
        super(key: key);

  @override
  _AppBarSearchState createState() => _AppBarSearchState();
}

class _AppBarSearchState extends State<AppBarSearch> {
  late TextEditingController _searchController;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _showClearButton = _searchController.text.isNotEmpty;
    });
  }


  Widget _buildMergedNotificationsAndMessages() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.blackColor, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 30.0, color: Palette.blackColor),
            onPressed: () {
              // Add your notifications action here.
            },
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            splashRadius: 20.0,
          ),
          Container(
            height: 24.0,
            width: 1.0,
            color: Palette.blackColor,
          ),
          IconButton(
            icon: const Icon(Icons.message, size: 30.0, color: Palette.blackColor),
            onPressed: () {
              // Add your messages action here.
            },
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            splashRadius: 20.0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: widget.preferredSize,
      child: Container(
        color: Palette.whiteColor,
        padding: const EdgeInsets.only(top: 16.0, left: 8.0, bottom: 8.0, right: 8.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Palette.blackColor, width: 1.0),
              ),
              child: IconButton(
                icon: Icon(Icons.menu, size: 30.0, color: Palette.blackColor),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                padding: const EdgeInsets.all(8.0),
                splashRadius: 20.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for Modern Jeepney ID',
                    hintStyle: TextStyle(
                      color: Palette.blackColor.withValues(alpha: 128),
                      fontSize: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Palette.greyColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 10.0,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Palette.blackColor,
                      size: 28.0,
                    ),
                    suffixIcon: _showClearButton
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Palette.blackColor.withAlpha(128)),
                            onPressed: () {
                              _searchController.clear();
                            },
                            splashRadius: 18.0,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                backgroundColor: Palette.blackColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(140, 50),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                // Implement your search action here.
              },
              child: Text(
                'Search',
                style: TextStyle(
                  color: Palette.whiteColor,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Palette.blackColor, width: 1.0),
              ),
              child: IconButton(
                icon: Icon(Icons.filter_list, size: 30.0, color: Palette.blackColor),
                onPressed: widget.onFilterPressed,
                padding: const EdgeInsets.all(8.0),
                splashRadius: 20.0,
              ),
            ),
            const SizedBox(width: 220.0),
            _buildMergedNotificationsAndMessages(),
            const SizedBox(width: 220.0),
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                ),
                child: Icon(Icons.account_circle, size: 30.0, color: Palette.blackColor),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Palette.blackColor, width: 1.0),
              ),
              color: Palette.whiteColor,
              onSelected: (String result) async {
                switch (result) {
                  case 'profile':
                    final currentAdminID = AuthService().currentAdminID;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        if (currentAdminID != null) {
                          return ProfilePopup();
                        } else {
                          return AlertDialog(
                            title: Text("Error"),
                            content: Text("Could not load profile. Admin ID missing."),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                          );
                        }
                      },
                    );
                    break;
                  case 'notification':
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return NotifPopUp();
                      },
                    );
                    break;
                  case 'security':
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SecurityPopUp();
                      },
                    );
                    break;
                  case 'updates':
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return UpdatesPopup();
                      },
                    );
                    break;
                  case 'logout':
                    await AuthService().clearAdminID();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login', 
                      (Route<dynamic> route) => false,
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Text('Profile'),
                ),
                const PopupMenuItem<String>(
                  height: 1,
                  padding: EdgeInsets.zero,
                  enabled: false,
                  child: Divider(color: Palette.greyColor, height: 1),
                ),
                const PopupMenuItem<String>(
                  value: 'notification',
                  child: Text('Notification'),
                ),
                const PopupMenuItem<String>(
                  height: 1,
                  padding: EdgeInsets.zero,
                  enabled: false,
                  child: Divider(color: Palette.greyColor, height: 1),
                ),
                const PopupMenuItem<String>(
                  value: 'security',
                  child: Text('Security'),
                ),
                const PopupMenuItem<String>(
                  height: 1,
                  padding: EdgeInsets.zero,
                  enabled: false,
                  child: Divider(color: Palette.greyColor, height: 1),
                ),
                const PopupMenuItem<String>(
                  value: 'updates',
                  child: Text('Updates'),
                ),
                const PopupMenuItem<String>(
                  height: 1,
                  padding: EdgeInsets.zero,
                  enabled: false,
                  child: Divider(color: Palette.greyColor, height: 1),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: Palette.redColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
