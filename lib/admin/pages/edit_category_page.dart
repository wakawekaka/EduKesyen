import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditCategoryPage extends StatefulWidget {
  final QueryDocumentSnapshot category;

  EditCategoryPage({required this.category});

  @override
  _EditCategoryPageState createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  String _categoryName = '';
  File? _imageFile;
  String _imageUrl = '';

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _categoryName = widget.category['name'];
    _imageUrl = widget.category['imgURL'];
  }

  Future<void> _updateCategory() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_imageFile != null) {
        // Upload new image to Firebase Storage
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('category_images')
            .child('${DateTime.now()}.jpg');
        UploadTask uploadTask = ref.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        _imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Update category data in Firestore
      await widget.category.reference.update({
        'name': _categoryName,
        'imgURL': _imageUrl,
      });

      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
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
        title: Text('Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _categoryName,
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
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 16.0),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 150,
                )
              else
                Image.network(
                  _imageUrl,
                  height: 150,
                ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateCategory,
                child: Text('Update Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
