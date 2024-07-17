import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCoursePage extends StatefulWidget {
  final DocumentReference courseRef;

  EditCoursePage({required this.courseRef});

  @override
  _EditCoursePageState createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    DocumentSnapshot courseDoc = await widget.courseRef.get();
    if (courseDoc.exists) {
      setState(() {
        _nameController.text = courseDoc['name'];
        _descriptionController.text = courseDoc['description'];
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      await widget.courseRef.update({
        'name': _nameController.text,
        'description': _descriptionController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Course Name'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Course Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
