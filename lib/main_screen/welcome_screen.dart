import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../student/main_page/student_screens.dart';

class WelcomeScreen extends StatelessWidget {
  Future<Map<String, dynamic>?> getUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('User not found'));
          } else {
            var userData = snapshot.data as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/getStarted.jpg', height: 150),
                    SizedBox(height: 20),
                    Text('Welcome ${userData['username']}!', style: TextStyle(fontSize: 24)),
                    SizedBox(height: 20),
                    Text('Awesome! Now let\'s explore more!', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => StudentScreen()));
                      },
                      child: Text('Get Started'),
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
