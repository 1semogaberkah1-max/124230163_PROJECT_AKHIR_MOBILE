// File: lib/pages/main_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Indeks tab yang sedang aktif

  // Daftar layar yang akan ditampilkan di tiap tab
  // Pastikan SEMUA LAYAR INI SUDAH ADA DI FOLDER LIB/PAGES dan LIB/SCREENS
  static const List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const FeedbackScreen(), // Layar Saran & Kesan
    const ProfileScreen(), // Layar Profil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Definisikan BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // Tab 1: Home
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Tab 2: Saran & Kesan
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Saran & Kesan',
          ),
          // Tab 3: Profil
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        // Warna akan diambil dari tema global
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
        onTap: _onItemTapped,
      ),
    );
  }
}
