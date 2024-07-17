import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_app_bar.dart';
import '../pages/course_detail.dart';

class StudentHomeScreen extends StatefulWidget {
  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String searchQuery = '';
  String selectedCategory = '';
  List<DocumentReference> enrolledCourseRefs = [];

  late User? _currentUser; // Firebase User object

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      fetchEnrolledCourses();
    }
  }

  Future<void> fetchEnrolledCourses() async {
    if (_currentUser == null) {
      return; // Return if user is not logged in
    }

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('enrolledCourses')
        .get();

    List<DocumentReference> refs = [];

    snapshot.docs.forEach((doc) {
      DocumentReference courseRef = doc['enrolled'];
      refs.add(courseRef);
    });

    setState(() {
      enrolledCourseRefs = refs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Edukesyen'),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: 'What are we learning today?',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
              SizedBox(height: 20),
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 154,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('category')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Something went wrong'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    List<DocumentSnapshot> categoryList = snapshot.data!.docs;

                    // Filter out "init" category
                    List<DocumentSnapshot> filteredCategory =
                        categoryList.where((category) {
                      String categoryName =
                          category['name'].toString().toLowerCase();
                      return categoryName != 'init';
                    }).toList();

                    if (filteredCategory.isEmpty) {
                      return Center(child: Text('No categories found'));
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredCategory.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot category = filteredCategory[index];
                        String categoryName =
                            category['name'].toString().toUpperCase();
                        String imgUrl = category['imgURL'];
                        bool isSelected = selectedCategory == category.id;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedCategory == category.id) {
                                selectedCategory = '';
                              } else {
                                selectedCategory = category.id;
                              }
                            });
                          },
                          child: _buildCategoryTile(
                              categoryName, imgUrl, isSelected),
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: 16),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: selectedCategory.isEmpty
                    ? FirebaseFirestore.instance
                        .collectionGroup('course')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('category')
                        .doc(selectedCategory)
                        .collection('course')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  List<DocumentSnapshot> courseList = snapshot.data!.docs;

                  // Filter courses based on search query, exclude "init" courses, and exclude enrolled courses
                  List<DocumentSnapshot> filteredCourses =
                      courseList.where((course) {
                    String courseName = course['name'].toString().toLowerCase();
                    DocumentReference courseRef = course.reference;

                    // Check if course reference is not in enrolledCourseRefs and exclude "init" courses
                    bool isEnrolled = enrolledCourseRefs
                        .any((ref) => ref.path == courseRef.path);

                    return !isEnrolled &&
                        courseName.contains(searchQuery) &&
                        courseName != 'init';
                  }).toList();

                  if (filteredCourses.isEmpty) {
                    return Center(child: Text('No courses found'));
                  }

                  return ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot course = filteredCourses[index];
                      String courseName = course['name'];
                      String courseDescription = course['description'];
                      String courseImgUrl = course['imgURL'];

                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CourseDetailScreen(course: course),
                            ),
                          );
                          if (result == true) {
                            fetchEnrolledCourses(); // Refresh enrolled courses
                          }
                        },
                        child: Column(
                          children: [
                            ListTile(
                              leading: Image.network(
                                courseImgUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                courseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(courseDescription),
                            ),
                            Divider(), // Add a divider between each course
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 10),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      String categoryName, String imgUrl, bool isSelected) {
    return Container(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              imgUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 8),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.black,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
