import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditModulePage extends StatefulWidget {
  final DocumentReference moduleRef;

  EditModulePage({required this.moduleRef});

  @override
  _EditModulePageState createState() => _EditModulePageState();
}

class _EditModulePageState extends State<EditModulePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModuleData();
  }

  Future<void> _loadModuleData() async {
    DocumentSnapshot moduleDoc = await widget.moduleRef.get();
    if (moduleDoc.exists) {
      setState(() {
        _nameController.text = moduleDoc['name'];
        _topicController.text = moduleDoc['topic'].toString();
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      await widget.moduleRef.update({
        'name': _nameController.text,
        'topic': int.parse(_topicController.text),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Module updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update module: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Module'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Module Name'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(labelText: 'Topic Number'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
