import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewRequestsScreen extends StatefulWidget {
  @override
  _ViewRequestsScreenState createState() => _ViewRequestsScreenState();
}

class _ViewRequestsScreenState extends State<ViewRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Teacher')
            .where('requestStatus', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending requests'));
          }
          final pendingTeachers = snapshot.data!.docs;
          return ListView.builder(
            itemCount: pendingTeachers.length,
            itemBuilder: (context, index) {
              final teacher = pendingTeachers[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                child: ListTile(
                  title: Text(teacher['username']),
                  subtitle: Text('Email: ${teacher['email']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      _showDetailsBottomSheet(context, teacher);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

void _showDetailsBottomSheet(BuildContext context, DocumentSnapshot teacher) async {
  DocumentReference categoryRef = teacher['category'];
  String categoryName = await getcategoryName(categoryRef); // Fetch category name asynchronously

  // Show the bottom sheet
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('Username: ${teacher['username']}'),
            SizedBox(height: 8),
            Text('Email: ${teacher['email']}'),
            SizedBox(height: 8),
            Text('Category: $categoryName'), // Display the fetched category name
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement accept functionality here
                    _handleAccept(teacher);
                    Navigator.pop(context); // Close bottom sheet after action
                  },
                  child: Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement decline functionality here
                    _handleDecline(teacher);
                    Navigator.pop(context); // Close bottom sheet after action
                  },
                  child: Text('Decline'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _handleAccept(DocumentSnapshot teacher) async {
  // Update the requestStatus to 'Accepted' in Firestore
  await teacher.reference.update({'requestStatus': 'Accepted'});
  await teacher.reference.update({'profile': 'https://firebasestorage.googleapis.com/v0/b/edukesyenassignment.appspot.com/o/default_profile.jpg?alt=media&token=ef8d392c-4a7c-47bc-bb94-912458d4a9a9'});
}

Future<void> _handleDecline(DocumentSnapshot teacher) async {
  // Update the requestStatus to 'Declined' in Firestore
  await teacher.reference.update({'requestStatus': 'Declined'});
}


  Future<String> getcategoryName(DocumentReference categoryRef) async {
    DocumentSnapshot categorySnapshot = await categoryRef.get();
    return categorySnapshot.exists ? categorySnapshot['name'] : 'No category';
  }
}
