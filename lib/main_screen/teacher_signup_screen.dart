import 'package:edukesyen/main_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSignupScreen extends StatefulWidget {
  @override
  _TeacherSignupScreenState createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();

  List<String> _categorys = [];
  String? _selectedcategory;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchcategorys();
  }

  Future<void> _fetchcategorys() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('category').get();
      List<String> categorys = querySnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      setState(() {
        _categorys = categorys;
      });
    } catch (e) {
      print("Error fetching categorys: $e");
    }
  }

  void _register() async {
    setState(() {
      _errorMessage = ''; // Clear any previous error message
    });

    if (_passwordController.text != _rePasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _errorMessage = 'Invalid email format';
      });
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Find the document reference in the "category" collection where "name" matches the selected category
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('name', isEqualTo: _selectedcategory)
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        // If a document with matching name is found, set the "category" field in user document to reference that document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text,
          'username': _usernameController.text,
          'role': 'Teacher',
          'category': categorySnapshot.docs[0].reference,
          'requestStatus': 'Pending',
        });
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Successful'),
          content: Text('Your account request has been submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginScreen()), // Replace LoginScreen with your actual login page
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Registration failed';
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Failed'),
          content: Text(_errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _rePasswordController,
                decoration: InputDecoration(
                  labelText: 'Re-enter Password',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedcategory,
                items: _categorys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select category',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedcategory = value;
                  });
                },
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty) // Display error message if it's not empty
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ElevatedButton(
                onPressed: _register,
                child: Text('Request Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
