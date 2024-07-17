import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edukesyen/main_screen/login_screen.dart';

class TeacherSettings extends StatefulWidget {
  @override
  _TeacherSettingsState createState() => _TeacherSettingsState();
}

class _TeacherSettingsState extends State<TeacherSettings> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  User? _currentUser;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _usernameController.text = userSnapshot['username'];
          _emailController.text = _currentUser!.email!;
          _profilePictureUrl = userSnapshot['profile'];
        });
      }
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('teacher_image')
          .child('${DateTime.now()}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> updateProfile(String username, String? profilePictureUrl) async {
    if (_currentUser != null) {
      Map<String, dynamic> updateData = {
        'username': username,
      };
      if (profilePictureUrl != null) {
        updateData['profile'] = profilePictureUrl;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updateData);
    }
  }

  Future<void> _changePassword() async {
    if (_currentUser != null && _passwordController.text.isNotEmpty) {
      try {
        await _currentUser!.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Settings'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(_currentUser?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Profile not found'));
          } else {
            var profileData = snapshot.data!.data() as Map<String, dynamic>;
            _usernameController.text = profileData['username'];
            _profilePictureUrl = profileData['profile'];

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _isEditing ? pickImage : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_profilePictureUrl != null ? NetworkImage(_profilePictureUrl!) : null) as ImageProvider?,
                              backgroundColor: Colors.transparent,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey[800],
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      if (_isEditing)
                        Text(
                          'Tap the picture to change it',
                          style: TextStyle(color: Colors.grey),
                        ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 10),
                      if (_emailController.text.isNotEmpty)
                        Text(
                          'Email: ${_emailController.text}',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      if (_isEditing)
                        SizedBox(height: 20),
                      if (_isEditing)
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: 20),
                      if (_isEditing)
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: 20),
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              String? imageUrl;
                              if (_imageFile != null) {
                                imageUrl = await uploadImage(_imageFile!);
                              }
                              await updateProfile(_usernameController.text, imageUrl);
                              await _changePassword();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Profile updated successfully')),
                              );
                              setState(() {
                                _isEditing = false;
                              });
                            }
                          },
                          child: Text('Update Profile'),
                        ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _logout,
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
