import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/custom_app_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<int> _getTotalModules() async {
    int totalModules = 0;
    QuerySnapshot categorySnapshot =
        await FirebaseFirestore.instance.collection('category').get();

    for (var categoryDoc in categorySnapshot.docs) {
      QuerySnapshot moduleSnapshot = await categoryDoc.reference
          .collection('course')
          .where('name', isNotEqualTo: 'init')
          .get();
      totalModules += moduleSnapshot.size;
    }
    return totalModules;
  }

  Future<int> _getTotalCourses() async {
    int totalCourses = 0;
    QuerySnapshot categorySnapshot =
        await FirebaseFirestore.instance.collection('category').get();

    for (var categoryDoc in categorySnapshot.docs) {
      QuerySnapshot courseSnapshot = await categoryDoc.reference
          .collection('course')
          .where('name', isNotEqualTo: 'init')
          .get();
      totalCourses += courseSnapshot.size;
    }
    return totalCourses;
  }

  Future<int> _getTotalStudents() async {
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .get();
    return studentSnapshot.size;
  }

  Future<int> _getTotalTeachers() async {
    QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Teacher')
        .where('requestStatus', isEqualTo: 'Accepted')
        .get();
    return teacherSnapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isNotEqualTo: 'Admin')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text('No users found.',
                          style: TextStyle(fontSize: 18));
                    }
                    final userCount = snapshot.data!.docs.length;
                    return Text(
                      'Total Users: $userCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('category')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text('No Category found.',
                          style: TextStyle(fontSize: 18));
                    }
                    final categoryCount = snapshot.data!.docs.length;
                    return Text(
                      'Total Categories: $categoryCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _getTotalCourses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    final courseCount = snapshot.data ?? 0;
                    return Text(
                      'Total Courses: $courseCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _getTotalModules(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    final moduleCount = snapshot.data ?? 0;
                    return Text(
                      'Total Modules: $moduleCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _getTotalStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    final studentCount = snapshot.data ?? 0;
                    return Text(
                      'Total Students: $studentCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _getTotalTeachers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    final teacherCount = snapshot.data ?? 0;
                    return Text(
                      'Total Teachers: $teacherCount',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                FutureBuilder<Map<String, int>>(
                  future: Future.wait([
                    _getTotalStudents(),
                    _getTotalTeachers(),
                  ]).then((values) => {
                        'Students': values[0],
                        'Teachers': values[1],
                      }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...', style: TextStyle(fontSize: 18));
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 18));
                    }
                    final data = snapshot.data ?? {'Students': 0, 'Teachers': 0};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Users',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: data['Students']!.toDouble(),
                                  title: 'Students',
                                  color: Colors.blue,
                                ),
                                PieChartSectionData(
                                  value: data['Teachers']!.toDouble(),
                                  title: 'Teachers',
                                  color: Colors.orange,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
