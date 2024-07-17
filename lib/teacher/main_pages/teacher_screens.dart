import 'package:flutter/material.dart';
import 'teacher_dashboard.dart';
import 'teacher_course.dart';
import 'teacher_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherScreen extends StatefulWidget {
  final DocumentSnapshot teacher;

  TeacherScreen({required this.teacher});

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _selectedIndex = 0;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(),
      CoursePage(),
      TeacherSettings(),
    ];
  }

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
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Color.fromRGBO(189, 224, 254, 1),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
