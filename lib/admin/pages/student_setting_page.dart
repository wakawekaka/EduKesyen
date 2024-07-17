import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSetting extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentSetting> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Page'),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Students',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No students found'));
                }

                final students = snapshot.data!.docs.where((student) {
                  return student['username']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery);
                }).toList();

                if (students.isEmpty) {
                  return Center(child: Text('No students found'));
                }
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text(student['username']),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentDetailPage(student: student),
                            ),
                          );
                        },
                        child: Text('View Details'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDetailPage extends StatelessWidget {
  final DocumentSnapshot student;

  StudentDetailPage({required this.student});

  Future<List<DocumentSnapshot>> getEnrolledCourses() async {
    QuerySnapshot coursesSnapshot = await student.reference
        .collection('enrolledCourses')
        .get();

    List<DocumentSnapshot> courses = [];

    for (var courseDoc in coursesSnapshot.docs) {
      DocumentReference courseRef = courseDoc['enrolled'];
      DocumentSnapshot courseSnapshot = await courseRef.get();
      courses.add(courseSnapshot);
    }

    return courses;
  }

  Future<void> deleteStudent() async {
    try {
      // Delete the student from Firestore
      await FirebaseFirestore.instance.collection('users').doc(student.id).delete();

      // Optionally, if students have authentication accounts, you can delete them from FirebaseAuth too
      // However, you need to handle authentication re-authentication before deleting the user
      // Example:
      // User? user = FirebaseAuth.instance.currentUser;
      // if (user != null && user.uid == student.id) {
      //   await user.delete();
      // }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  void confirmRemoveStudent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove'),
          content: Text('Are you sure you want to remove this student?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                removeStudent(context);
              },
            ),
          ],
        );
      },
    );
  }

  void removeStudent(BuildContext context) async {
    try {
      await deleteStudent();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student removed successfully')),
      );

      Navigator.pop(context);
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove student: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(student['profile']),
              ),
              SizedBox(height: 16.0),
              Text(
                student['username'].toUpperCase(),
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                student['email'],
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Enrolled Courses:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final course = snapshot.data![index];
                        return ListTile(
                          title: Text(course['name']),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => confirmRemoveStudent(context),
                child: Text('Remove Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
