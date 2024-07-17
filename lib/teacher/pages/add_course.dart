import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddCoursePage extends StatefulWidget {
  @override
  _AddCoursePageState createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _formKey = GlobalKey<FormState>();
  String _courseName = '';
  String _description = '';
  File? _imageFile;
  String _imageUrl = '';

  final picker = ImagePicker();

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        // Display error message if no image is selected
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please select an image.'),
        ));
        return;
      }

      _formKey.currentState!.save();

      // Check if user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is authenticated, proceed with adding course
        // Upload image to Firebase Storage
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('teacher_images')
            .child('${DateTime.now()}.jpg');
        UploadTask uploadTask = ref.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        _imageUrl = await snapshot.ref.getDownloadURL();

        // Get the current user's document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Get the category reference from the user's document
        DocumentReference? categoryRef = userDoc['category'];
        if (categoryRef != null) {
          // Add course data to the category's course sub-collection
          await categoryRef.collection('course').add({
            'name': _courseName,
            'description': _description,
            'imgURL': _imageUrl,
            'teacher': userDoc.reference,
          });
          
          Navigator.pop(context);
        } else {
          // Handle the case where the category reference is not found
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Category not found for the current user.'),
          ));
        }
      } else {
        // Handle the case where the user is not authenticated
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User not authenticated.'),
        ));
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Course'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Course Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _courseName = value!;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
                maxLines: null, // Allow multiline input
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 16.0),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 150,
                ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addCourse,
                child: Text('Add Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
