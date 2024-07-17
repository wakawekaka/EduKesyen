import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edukesyen/widgets/custom_app_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  Future<DocumentReference?> _getCurrentTeacherCategoryRef() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc['category'] as DocumentReference?;
    }
    return null;
  }

  Future<int> _getTotalCourses(DocumentReference categoryRef) async {
    int totalCourses = 0;
    QuerySnapshot courseSnapshot = await categoryRef
        .collection('course')
        .where('name', isNotEqualTo: 'init')
        .get();
    totalCourses = courseSnapshot.size;
    return totalCourses;
  }

  Future<int> _getTotalModules(DocumentReference categoryRef) async {
    int totalModules = 0;
    QuerySnapshot courseSnapshot = await categoryRef
        .collection('course')
        .where('name', isNotEqualTo: 'init')
        .get();

    for (var courseDoc in courseSnapshot.docs) {
      QuerySnapshot moduleSnapshot =
          await courseDoc.reference.collection('module').get();
      totalModules += moduleSnapshot.size;
    }
    return totalModules;
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
            child: FutureBuilder<DocumentReference?>(
              future: _getCurrentTeacherCategoryRef(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text(
                    'Error: ${snapshot.error ?? 'Failed to get category reference'}',
                    style: TextStyle(fontSize: 18),
                  );
                }
                final categoryRef = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<int>(
                      future: _getTotalCourses(categoryRef),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading...',
                              style: TextStyle(fontSize: 18));
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}',
                              style: TextStyle(fontSize: 18));
                        }
                        final courseCount = snapshot.data ?? 0;
                        return Text(
                          'Total Courses: $courseCount',
                          style: const TextStyle(fontSize: 18),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<int>(
                      future: _getTotalModules(categoryRef),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading...',
                              style: TextStyle(fontSize: 18));
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}',
                              style: TextStyle(fontSize: 18));
                        }
                        final moduleCount = snapshot.data ?? 0;
                        return Text(
                          'Total Modules: $moduleCount',
                          style: const TextStyle(fontSize: 18),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
