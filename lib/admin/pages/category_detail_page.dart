import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot category;

  CategoryDetailPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category['name']),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getCourseList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No courses found'));
          }

          final courses = snapshot.data!.docs
              .where((doc) => doc['name'] != 'init')
              .toList();

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Column(
                children: [
                  ListTile(
                    title: Text(course['name']),
                  ),
                  Divider(), 
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<QuerySnapshot> _getCourseList() async {
    return await category.reference.collection('course').get();
  }
}

class CourseDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot course;

  CourseDetailPage({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
