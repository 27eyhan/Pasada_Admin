import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class AppBarSearch extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  AppBarSearch({Key? key})
      : preferredSize = const Size.fromHeight(70.0),
        super(key: key);

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double iconSize = 30.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Palette.blackColor, width: 1.0),
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: Palette.blackColor),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8.0),
        splashRadius: 20.0,
      ),
    );
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
    return Scaffold(
      drawer: MyDrawer(),
      appBar: PreferredSize(
        preferredSize: preferredSize,
        child: Container(
          color: Palette.whiteColor,
          padding: const EdgeInsets.only(top: 16.0, left: 8.0, bottom: 8.0, right: 8.0),
          child: Row(
            children: [
              _buildCircularIconButton(
                icon: Icons.menu,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: TextField(
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
              _buildCircularIconButton(
                icon: Icons.filter_list,
                onPressed: () {
                  // Add your filter action here.
                },
                iconSize: 30.0,
              ),
              const SizedBox(width: 220.0),
              _buildMergedNotificationsAndMessages(),
              const SizedBox(width: 220.0),
              _buildCircularIconButton(
                icon: Icons.account_circle,
                onPressed: () {
                  // Add your profile action here.
                },
                iconSize: 30.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
