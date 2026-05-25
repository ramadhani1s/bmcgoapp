import 'package:flutter/material.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.accentColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: accentColor,
      unselectedItemColor: const Color(0xFF8F91A0),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11.5,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded),
          label: 'Materi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Try Out',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}
