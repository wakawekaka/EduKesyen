import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDetailPage extends StatelessWidget {
  final DocumentSnapshot teacher;

  TeacherDetailPage({required this.teacher});

  Future<String> getCategoryName(DocumentReference categoryRef) async {
    DocumentSnapshot categorySnapshot = await categoryRef.get();
    return categorySnapshot.exists ? categorySnapshot['name'] : 'No category';
  }

  Future<List<DocumentSnapshot>> getTeacherCourses() async {
    List<DocumentSnapshot> courseDocs = [];

    QuerySnapshot categorySnapshot =
        await FirebaseFirestore.instance.collection('category').get();

    for (var categoryDoc in categorySnapshot.docs) {
      QuerySnapshot courseSnapshot = await categoryDoc.reference
          .collection('course')
          .where('teacher', isEqualTo: teacher.reference)
          .get();

      courseDocs.addAll(courseSnapshot.docs);
    }

    return courseDocs;
  }

  Future<int> getModuleCount(DocumentReference courseRef) async {
    QuerySnapshot moduleSnapshot = await courseRef
        .collection('module')
        .where('name', isNotEqualTo: 'init')
        .get();
    return moduleSnapshot.size;
  }

  void removeTeacher(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(teacher.id)
          .delete();

      // Remove from Firebase Authentication
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teacher removed successfully')),
      );

      Navigator.pop(context);  // Navigate back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove teacher: $e')),
      );
    }
  }

  void confirmRemoveTeacher(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove'),
          content: Text('Are you sure you want to remove this teacher?'),
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
                removeTeacher(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference categoryRef = teacher['category'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(teacher['profile']),
              ),
              SizedBox(height: 16.0),
              Text(
                teacher['username'].toUpperCase(),
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                teacher['email'],
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              SizedBox(height: 8.0),
              FutureBuilder<String>(
                future: getCategoryName(categoryRef),
                builder: (context, categorySnapshot) {
                  if (categorySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!categorySnapshot.hasData) {
                    return Text(
                      'Category not found',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.red,
                      ),
                    );
                  }
                  return Text(
                    categorySnapshot.data!,
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => confirmRemoveTeacher(context),
                child: Text('Remove Teacher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Courses:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FutureBuilder<List<DocumentSnapshot>>(
                future: getTeacherCourses(),
                builder: (context, courseSnapshot) {
                  if (courseSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!courseSnapshot.hasData || courseSnapshot.data!.isEmpty) {
                    return Text('No courses found');
                  }
                  return Expanded(
                    child: ListView.builder(
                      itemCount: courseSnapshot.data!.length,
                      itemBuilder: (context, index) {
                        final course = courseSnapshot.data![index];
                        return FutureBuilder<int>(
                          future: getModuleCount(course.reference),
                          builder: (context, moduleSnapshot) {
                            if (moduleSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text(course['name']),
                                subtitle: Text('Loading modules...'),
                              );
                            }
                            if (!moduleSnapshot.hasData) {
                              return ListTile(
                                title: Text(course['name']),
                                subtitle: Text('Modules not found'),
                              );
                            }
                            return ListTile(
                              title: Text(course['name']),
                              subtitle: Text('Total modules: ${moduleSnapshot.data}'),
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
