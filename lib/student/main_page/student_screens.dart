import 'student_enrolled_course.dart';
import 'package:flutter/material.dart';
import 'student_setting.dart';
import 'student_home_screen.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    StudentHomeScreen(),
    StudentEnrolledCourse(),
    StudentSetting(),
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
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: const Color.fromRGBO(189, 224, 254, 1),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmarks),
            label: 'Enrolled Courses',
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
