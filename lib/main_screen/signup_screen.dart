import 'package:edukesyen/main_screen/teacher_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();
  String _errorMessage = '';

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

      // Add user details to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text,
        'username': _usernameController.text,
        'role': 'Student',
        'profile': 'https://firebasestorage.googleapis.com/v0/b/edukesyenassignment.appspot.com/o/default_profile.jpg?alt=media&token=ef8d392c-4a7c-47bc-bb94-912458d4a9a9'
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Successful'),
          content: Text('You have successfully registered.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Go back to the previous screen
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
                child: Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TeacherSignupScreen()),
                  );
                },
                child: Text('Sign up as Teacher?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
