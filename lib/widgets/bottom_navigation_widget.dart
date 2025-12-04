import 'package:flutter/material.dart';

/// Bottom Navigation Widget for Document Upload Screen
/// Part of Test Figma / Confirm Information feature
/// Decorative only - no navigation functionality
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.grey[800],
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 1, // Second icon (documents) is selected
      onTap: (index) {
        // Decorative only - no action
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Documents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'Forms',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'People',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer_outlined),
          label: 'Offers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events_outlined),
          label: 'Rewards',
        ),
      ],
    );
  }
}

