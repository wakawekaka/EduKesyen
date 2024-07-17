import 'package:edukesyen/admin/pages/category_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/add_category_page.dart';
import '../../widgets/custom_app_bar.dart';
import '../pages/edit_category_page.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Category'),
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
                          builder: (context) => AddCategoryPage()),
                    );
                  },
                  child: Text('Add Category'),
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
                    .collection('category')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No categories found'));
                  }

                  final categories = snapshot.data!.docs.where((category) {
                    return category['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery);
                  }).toList();

                  if (categories.isEmpty) {
                    return Center(child: Text('No categories found'));
                  }

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryListTile(category: category);
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

class CategoryListTile extends StatelessWidget {
  final QueryDocumentSnapshot category;

  CategoryListTile({required this.category});

  Future<int> _getCourseCount() async {
    final courseSnapshot = await category.reference.collection('course').get();
    final filteredCourses =
        courseSnapshot.docs.where((doc) => doc['name'] != 'init');
    return filteredCourses.length;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this category?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _deleteCategory(context); // Call the delete function
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(BuildContext context) async {
    try {
      await category.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Category deleted successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete category: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getCourseCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: Image.network(category['imgURL'],
                width: 50, height: 50, fit: BoxFit.cover),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'], // Make the category name bold
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Tap for more details',
                  style: TextStyle(color: Colors.blue), // Change color to blue
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loading courses...'),
              ],
            ),
            onTap: () {
              _navigateToCategoryDetail(context, category);
            },
          );
        }
        if (snapshot.hasError) {
          return ListTile(
            leading: Image.network(category['imgURL'],
                width: 50, height: 50, fit: BoxFit.cover),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'], // Make the category name bold
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Tap for more details',
                  style: TextStyle(color: Colors.blue), // Change color to blue
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error loading courses'),
              ],
            ),
            onTap: () {
              _navigateToCategoryDetail(context, category);
            },
          );
        }
        // Check if snapshot has data before displaying the total courses
        if (snapshot.hasData) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Image.network(category['imgURL'],
                  width: 50, height: 50, fit: BoxFit.cover),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'], // Make the category name bold
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Tap for more details',
                    style:
                        TextStyle(color: Colors.blue), // Change color to blue
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total courses: ${snapshot.data ?? 0}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditCategoryPage(category: category),
                            ),
                          );
                        },
                        child: Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () {
                          _confirmDelete(context);
                        },
                        child: Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                _navigateToCategoryDetail(context, category);
              },
            ),
          );
        } else {
          // If snapshot has no data, display a placeholder or an error message
          return Container(); // You can return any placeholder widget here
        }
      },
    );
  }

  void _navigateToCategoryDetail(
      BuildContext context, QueryDocumentSnapshot category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(category: category),
      ),
    );
  }
}
