import 'package:alpha_go/controllers/vibe_controller.dart';
import 'package:alpha_go/controllers/wallet_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/views/screens/events_list_screen.dart';
import 'package:alpha_go/views/screens/home_screen.dart';
import 'package:alpha_go/views/screens/profile_screen.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const mapTab = 2;
  int _selectedIndex = mapTab;
  static final List<Widget> _widgetOptions = <Widget>[
    const EventsListScreen(),
    const ProfilePage(),
    const MapHomePage(),
  ];
  static const List<IconData> iconList = <IconData>[
    Icons.view_list,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    final mnemonic = Get.find<WalletController>().mnemonic;
    if (mnemonic != null) Get.find<VibeController>().load(mnemonic);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: _selectedIndex == mapTab,
        backgroundColor: Colors.black,
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          shape: const CircleBorder(side: BorderSide(color: Constants.gold)),
          child: Icon(Icons.map, size: 26.sp, color: Constants.gold),
          onPressed: () => setState(() => _selectedIndex = mapTab),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          borderColor: Constants.gold,
          backgroundColor: Colors.black,
          itemCount: iconList.length,
          tabBuilder: (int index, bool isActive) => Icon(
            iconList[index],
            size: 26.sp,
            color: isActive ? Constants.gold : Colors.white54,
          ),
          activeIndex: _selectedIndex == mapTab ? -1 : _selectedIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          leftCornerRadius: 21.sp,
          rightCornerRadius: 21.sp,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
