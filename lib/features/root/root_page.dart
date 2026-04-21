import 'package:flutter/material.dart';

import '../../shared/widgets/custom_bottom_nav.dart';
import '../activity/activity_page.dart';
import '../home/home_page.dart';
import '../nutrition/nutrition_page.dart';
import '../profile/profile_page.dart';
import '../shop/shop_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ActivityPage(),
    NutritionPage(),
    ShopPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}