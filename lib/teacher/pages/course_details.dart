import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'module_details.dart'; // Import ModuleDetailsPage
import 'add_module.dart'; // Import AddModulePage
import 'edit_module.dart'; // Import EditModulePage

class CourseDetailsPage extends StatelessWidget {
  final DocumentReference courseRef;

  CourseDetailsPage({required this.courseRef});

  Future<void> _deleteModule(BuildContext context, DocumentReference moduleRef) async {
    try {
      await moduleRef.delete();
      _showSnackBar(context, 'Module deleted successfully');
    } catch (e) {
      print('Error deleting module: $e');
      _showSnackBar(context, 'Failed to delete module');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: courseRef.collection('module').orderBy('topic').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No modules found'));
                }
                // Display modules
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final module = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(module['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Topic: ${module['topic']}'),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModuleDetailsPage(module: module),
                                ),
                              );
                            },
                            child: Text(
                              'Tap to View Video',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ModuleDetailsPage(module: module),
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
                                  builder: (context) => EditModulePage(moduleRef: module.reference),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              // Confirm deletion
                              bool? confirmDelete = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete this module?'),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: Text('Delete'),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete == true) {
                                _deleteModule(context, module.reference);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddModulePage(courseRef: courseRef),
                  ),
                );
                _showSnackBar(context, 'Module added successfully');
              },
              child: Text(
                'Add Module',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(height: 40), // Add space to the bottom
        ],
      ),
    );
  }
}
