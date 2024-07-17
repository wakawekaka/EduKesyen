import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddModulePage extends StatefulWidget {
  final DocumentReference courseRef;

  AddModulePage({required this.courseRef});

  @override
  _AddModulePageState createState() => _AddModulePageState();
}

class _AddModulePageState extends State<AddModulePage> {
  final _formKey = GlobalKey<FormState>();
  String _moduleName = '';
  int _topic = 1;
  File? _videoFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _videoURL;
  UploadTask? _uploadTask;

  Future<void> _addModule() async {
    if (_formKey.currentState!.validate()) {
      if (_videoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please pick a video.'),
          ),
        );
        return;
      }

      _formKey.currentState!.save();

      setState(() {
        _isUploading = true;
      });

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('teacher_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        _uploadTask = storageRef.putFile(_videoFile!);

        _uploadTask!.snapshotEvents.listen((event) {
          setState(() {
            _uploadProgress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
          });
        });

        final snapshot = await _uploadTask!.whenComplete(() => {});
        _videoURL = await snapshot.ref.getDownloadURL();

        setState(() {
          _isUploading = false;
        });
      } catch (error) {
        print("Error uploading video: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video.'),
          ),
        );

        setState(() {
          _isUploading = false;
        });

        return;
      }

      try {
        await widget.courseRef.collection('module').add({
          'name': _moduleName,
          'topic': _topic,
          'videoURL': _videoURL,
        });

        Navigator.pop(context);
      } catch (error) {
        print("Error adding module: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add module.'),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  void _deleteVideo() {
    setState(() {
      _videoFile = null;
      _uploadTask = null;
      _uploadProgress = 0.0;
    });
  }

  void _cancelUpload() {
    if (_uploadTask != null) {
      _uploadTask!.cancel();
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadTask = null;
        _videoFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Module'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Module Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a module name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _moduleName = value!;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Topic Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _topic = int.parse(value!);
                },
              ),
              SizedBox(height: 16.0),
              if (_videoFile == null)
                ElevatedButton(
                  onPressed: _pickVideo,
                  child: Text('Pick Video'),
                ),
              if (_videoFile != null && !_isUploading)
                Column(
                  children: [
                    Text('Video selected: ${_videoFile!.path.split('/').last}'),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _deleteVideo,
                      child: Text('Delete Video'),
                    ),
                  ],
                ),
              if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
              if (_isUploading) Text('${(_uploadProgress * 100).toStringAsFixed(2)}% uploaded'),
              if (_isUploading)
                ElevatedButton(
                  onPressed: _cancelUpload,
                  child: Text('Cancel Upload'),
                ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addModule,
                child: Text('Add Module'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
