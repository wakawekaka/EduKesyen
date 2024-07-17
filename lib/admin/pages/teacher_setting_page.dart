import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_request_page.dart';
import 'teacher_detail_page.dart';

class TeacherSetting extends StatefulWidget {
  @override
  _TeacherSettingState createState() => _TeacherSettingState();
}

class _TeacherSettingState extends State<TeacherSetting> {
  String searchQuery = '';
  String selectedCategory = '';

  Future<String> getCategoryName(DocumentReference categoryRef) async {
    DocumentSnapshot categorySnapshot = await categoryRef.get();
    return categorySnapshot.exists ? categorySnapshot['name'] : 'No category';
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FilterSheet(
          selectedCategory: selectedCategory,
          onSelected: (category) {
            setState(() {
              selectedCategory = category;
            });
            Navigator.pop(context);
          },
          onClear: () {
            setState(() {
              selectedCategory = '';
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher'),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                      MaterialPageRoute(
                        builder: (context) => ViewRequestsScreen(),
                      ),
                    );
                  },
                  child: Text('View Requests'),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: showFilterSheet,
                  child: Text('Filter'),
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
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'Teacher')
                    .where('requestStatus', isEqualTo: 'Accepted')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No teachers found'));
                  }
                  final teachers = snapshot.data!.docs.where((teacher) {
                    final matchesSearch = teacher['username']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery);
                    if (selectedCategory.isEmpty) {
                      return matchesSearch;
                    } else {
                      final categoryRef = teacher['category'] as DocumentReference;
                      return matchesSearch && categoryRef.id == selectedCategory;
                    }
                  }).toList();
                  return ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      DocumentReference categoryRef = teacher['category'];
                      return FutureBuilder<String>(
                        future: getCategoryName(categoryRef),
                        builder: (context, categorySnapshot) {
                          if (categorySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              title: Text(teacher['username']),
                              subtitle: Text('Loading category...'),
                              trailing: CircularProgressIndicator(),
                            );
                          }
                          if (!categorySnapshot.hasData) {
                            return ListTile(
                              title: Text(teacher['username']),
                              subtitle: Text('Category not found'),
                            );
                          }
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(teacher['username']),
                              subtitle: Text(categorySnapshot.data!),
                              trailing: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TeacherDetailPage(teacher: teacher),
                                    ),
                                  );
                                },
                                child: Text('Detail'),
                              ),
                            ),
                          );
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
}

class FilterSheet extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onSelected;
  final Function() onClear;

  const FilterSheet({
    required this.selectedCategory,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Category:',
            style: TextStyle(fontSize: 16.0),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('category').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No categories found'));
                }
                final categories = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(category['name']),
                      onTap: () {
                        onSelected(category.id);
                      },
                      selected: selectedCategory == category.id,
                      selectedTileColor: Colors.grey[300],
                    );
                  },
                );
              },
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text('Clear Filter'),
          ),
        ],
      ),
    );
  }
}
