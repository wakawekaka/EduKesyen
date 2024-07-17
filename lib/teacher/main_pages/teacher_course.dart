import 'package:edukesyen/teacher/pages/edit_course.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edukesyen/widgets/custom_app_bar.dart';
import 'package:edukesyen/teacher/pages/add_course.dart';
import 'package:edukesyen/teacher/pages/course_details.dart';

class CoursePage extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  String searchQuery = '';
  late Stream<QuerySnapshot> _coursesStream;

  @override
  void initState() {
    super.initState();
    _coursesStream = _getCoursesStream();
  }

  Stream<QuerySnapshot> _getCoursesStream() async* {
    final categoryRef = await _getCurrentTeacherCategoryRef();
    if (categoryRef != null) {
      yield* categoryRef
          .collection('course')
          .where('name', isNotEqualTo: 'init')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Courses'),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCoursePage()),
                    );
                  },
                  child: Text('Add Course'),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _coursesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No courses found'));
                  }

                  final courses = snapshot.data!.docs.where((course) {
                    return course['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery);
                  }).toList();

                  if (courses.isEmpty) {
                    return Center(child: Text('No courses found'));
                  }

                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return CourseListTile(
                        course: course,
                        onDelete: () {
                          _deleteCourse(course.reference);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _deleteCourse(DocumentReference courseRef) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        await courseRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course deleted successfully'),
          ),
        );
      }
    } catch (error) {
      print('Error deleting course: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete course'),
        ),
      );
    }
  }
}

class CourseListTile extends StatelessWidget {
  final DocumentSnapshot course;
  final VoidCallback onDelete;

  CourseListTile({required this.course, required this.onDelete});

  Stream<int> _getModuleCount() {
    return course.reference
        .collection('module')
        .where('name', isNotEqualTo: 'init')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            NetworkImage(course['imgURL']), // Load image from Firebase URL
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course['name'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          StreamBuilder<int>(
            stream: _getModuleCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              return Text(
                'Total modules: ${snapshot.data ?? 0}',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course['description'],
            maxLines: 2, // Limit to 2 lines for description
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
              height: 4.0), // Add some space between description and tap text
          Text(
            'Tap to view details',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CourseDetailsPage(courseRef: course.reference),
          ),
        );
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditCoursePage(courseRef: course.reference),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
