import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.directions_run_outlined), label: 'Aktivitas'),
        NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), label: 'Nutrisi'),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}