import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';
import 'package:edukesyen/admin/main_page/admin_screens.dart';
import 'package:edukesyen/teacher/main_pages/teacher_screens.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        if (role == 'Teacher') {
          String requestStatus = userDoc['requestStatus'];
          if (requestStatus == 'Accepted') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => TeacherScreen(teacher: userDoc)),
            );
          } else {
            setState(() {
              _errorMessage = requestStatus == 'Pending'
                  ? "Your request is still pending. Please wait for approval."
                  : "Your request has been declined.";
            });
          }
        } else if (role == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else {
          //Student
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WelcomeScreen(),
              ));
        }
      } else {
        setState(() {
          _errorMessage = "User document does not exist.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'The user corresponding to the given email has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      default:
        return 'Email or password is incorrect.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 50),
              Image.asset('assets/images/cat.jpg', height: 150),
              SizedBox(height: 20),
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
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.greenAccent,
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text('Don’t have an account? Sign Up!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
