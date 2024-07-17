import 'package:flutter/material.dart';
import 'category_page.dart';
import 'dashboard_page.dart';
import 'panel_page.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    DashboardPage(),
    CategoryPage(),
    PanelPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor:
            Colors.blue[900], // Change selected item color to dark blue
        unselectedItemColor: const Color.fromRGBO(
            189, 224, 254, 1), // Change unselected item color to light blue
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Panel',
          ),
        ],
      ),
    );
  }
}
