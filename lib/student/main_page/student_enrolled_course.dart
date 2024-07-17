import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_app_bar.dart';
import '../pages/course_detail.dart'; // Adjust the import to your file structure

class StudentEnrolledCourse extends StatefulWidget {
  @override
  _StudentEnrolledCourseState createState() => _StudentEnrolledCourseState();
}

class _StudentEnrolledCourseState extends State<StudentEnrolledCourse> {
  late User? _currentUser; // Firebase User object

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<List<DocumentSnapshot>> getEnrolledCourses() async {
    if (_currentUser == null) {
      return []; // Return empty list if user is not logged in
    }

    // Reference to the collection of enrolled courses for the current user
    QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
        .collection('users') // Adjust 'students' to your collection name
        .doc(_currentUser!
            .uid) // Assuming student document ID is the same as user UID
        .collection('enrolledCourses')
        .get();

    return coursesSnapshot.docs; // Return list of DocumentSnapshot
  }

  Future<void> refreshEnrolledCourses() async {
    setState(() {
      // Trigger a rebuild to refresh the UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Enrolled Courses'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 16.0),
              FutureBuilder<List<DocumentSnapshot>>(
                future: getEnrolledCourses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No enrolled courses found');
                  }
                  return Expanded(
                    child: ListView.separated(
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final courseRef = snapshot.data![index].get('enrolled');
                        return FutureBuilder<DocumentSnapshot>(
                          future: courseRef.get(),
                          builder: (context, courseSnapshot) {
                            if (courseSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (!courseSnapshot.hasData ||
                                !courseSnapshot.data!.exists) {
                              return Text('Course not found');
                            }
                            final courseData = courseSnapshot.data!;
                            return InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(
                                      course: courseData,
                                    ),
                                  ),
                                );
                                // After returning from CourseDetailScreen, refresh the enrolled courses
                                refreshEnrolledCourses();
                              },
                              child: ListTile(
                                leading: Image.network(
                                  courseData['imgURL'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  courseData['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(courseData['description']),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
