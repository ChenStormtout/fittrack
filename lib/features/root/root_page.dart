import 'package:flutter/material.dart';

import '../../shared/widgets/ai_chat_fab.dart';
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

  static const List<Widget> _pages = [
    HomePage(),
    ActivityPage(),
    NutritionPage(),
    ShopPage(),
    ProfilePage(),
  ];

  // Shop is index 3 — FAB hidden there
  bool get _showFab => _currentIndex != 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _showFab ? const AiChatFab() : null,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}