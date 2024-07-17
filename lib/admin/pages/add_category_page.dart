import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddCategoryPage extends StatefulWidget {
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  String _categoryName = '';
  File? _imageFile;
  String _imageUrl = '';

  final picker = ImagePicker();

  Future<void> _uploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addCategory() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an image.'),
          ),
        );
        return; // Return if image is not selected
      }

      _formKey.currentState!.save();

      // Upload image to Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child('category_images').child('${DateTime.now()}.jpg');
      UploadTask uploadTask = ref.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      _imageUrl = await snapshot.ref.getDownloadURL();

      // Add category data to Firestore
      DocumentReference categoryRef = await FirebaseFirestore.instance.collection('category').add({
        'name': _categoryName,
        'imgURL': _imageUrl,
      });

      // Add initial course
      await categoryRef.collection('course').add({
        'name': 'init',
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Category'),
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
                decoration: InputDecoration(labelText: 'Category Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _categoryName = value!;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 16.0),
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      height: 150,
                    )
                  : SizedBox(),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addCategory,
                child: Text('Add Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
