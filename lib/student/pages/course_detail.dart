import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'module_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final DocumentSnapshot course;

  CourseDetailScreen({required this.course});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late bool isEnrolled = false;
  var user = FirebaseAuth.instance.currentUser;
  Map<String, bool> completedModules = {};

  @override
  void initState() {
    super.initState();
    checkEnrollmentStatus();
    loadCompletedModules();
  }

  Future<void> checkEnrollmentStatus() async {
    if (user == null) {
      return;
    }

    final userId = user!.uid;
    final courseReference = widget.course.reference;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .where('enrolled', isEqualTo: courseReference)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          isEnrolled = true;
        });
      }
    } catch (e) {
      print('Error checking enrollment status: $e');
    }
  }

  Future<void> loadCompletedModules() async {
    if (user == null) {
      return;
    }

    final userId = user!.uid;
    final courseReference = widget.course.reference;

    try {
      var enrolledCourseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .where('enrolled', isEqualTo: courseReference)
          .get();

      if (enrolledCourseSnapshot.docs.isNotEmpty) {
        var completedModulesSnapshot = await enrolledCourseSnapshot.docs.first.reference
            .collection('completedModules')
            .get();

        setState(() {
          completedModules = {
            for (var doc in completedModulesSnapshot.docs) doc.id: doc['completed'] as bool
          };
        });
      }
    } catch (e) {
      print('Error loading completed modules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.course['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isEnrolled)
                    ElevatedButton(
                      onPressed: () => confirmUnenroll(context),
                      child: Text('Unenroll this Course'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => enrollCourse(context),
                      child: Text('Enroll this Course'),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                widget.course['description'],
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.course['teacher'].id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('Teacher information not found'));
                  }

                  var teacher = snapshot.data!;
                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          teacher['profile'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher['username'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            teacher['email'],
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                'Modules:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: widget.course.reference
                    .collection('module')
                    .orderBy('topic')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }

                  var modules = snapshot.data!.docs;

                  if (modules.isEmpty) {
                    return Center(child: Text('No modules found'));
                  }

                  return ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      var module = modules[index];
                      var moduleId = module.id;
                      var isCompleted = completedModules[moduleId] ?? false;

                      return ListTile(
                        title: Text(
                          'Module ${module['topic']}: ${module['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          Icons.check_circle,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModuleDetailScreen(
                                module: module,
                                courseReference: widget.course.reference,
                                isEnrolled: isEnrolled,
                                isCompleted: isCompleted,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              loadCompletedModules();
                            }
                          });
                        },
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 10),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> enrollCourse(BuildContext context) async {
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = user.uid;
    final courseReference = widget.course.reference;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .add({
        'enrolled': courseReference,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrolled successfully')),
      );

      setState(() {
        isEnrolled = true;
      });

      // Return true to indicate enrollment status changed
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll: $e')),
      );
    }
  }

  Future<void> unenrollCourse(BuildContext context) async {
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = user.uid;
    final courseReference = widget.course.reference;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .where('enrolled', isEqualTo: courseReference)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('enrolledCourses')
            .doc(snapshot.docs.first.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unenrolled successfully')),
        );

        setState(() {
          isEnrolled = false;
        });
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll: $e')),
      );
    }
  }

  Future<void> confirmUnenroll(BuildContext context) async {
    bool confirmed = false;
    confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Unenrollment'),
            content:
                Text('Are you sure you want to unenroll from this course?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Unenroll'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      unenrollCourse(context);
    }
  }
}
