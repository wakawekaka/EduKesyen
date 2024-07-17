import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../main_screen/login_screen.dart';

class StudentSetting extends StatefulWidget {
  @override
  _StudentSettingState createState() => _StudentSettingState();
}

class _StudentSettingState extends State<StudentSetting> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  Future<Map<String, dynamic>?> getUserProfile() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data();
    }
    return null;
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
          .child('student_image')
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
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Map<String, dynamic> updateData = {
        'username': username,
      };
      if (profilePictureUrl != null) {
        updateData['profile'] = profilePictureUrl;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);
    }
  }

  Future<void> _changePassword() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null && _passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      try {
        await user.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
        // Clear password fields after successful update
        _passwordController.clear();
        _confirmPasswordController.clear();
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
        title: Text('Student Settings'),
        automaticallyImplyLeading: false,
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Profile not found'));
          } else {
            var profileData = snapshot.data!;
            _usernameController.text = profileData['username'];
            String profilePictureUrl = profileData['profile'] ?? '';
            var user = FirebaseAuth.instance.currentUser;
            String? email = user?.email;

            return Padding(
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
                                : NetworkImage(profilePictureUrl)
                                    as ImageProvider,
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
                    if (!_isEditing)
                      Text(
                        email ?? '',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    if (_isEditing) SizedBox(height: 20),
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
                    SizedBox(height: 10),
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
                    if (!_isEditing)
                      ElevatedButton(
                        onPressed: _logout,
                        child: Text('Logout'),
                      ),
                    if (_isEditing)
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            String? imageUrl;
                            if (_imageFile != null) {
                              imageUrl = await uploadImage(_imageFile!);
                            }
                            await updateProfile(
                                _usernameController.text, imageUrl);
                            await _changePassword();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Profile updated successfully')),
                            );
                            setState(() {
                              _isEditing = false;
                            });
                          }
                        },
                        child: Text('Update Profile'),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
