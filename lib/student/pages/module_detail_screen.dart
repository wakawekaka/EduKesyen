import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class ModuleDetailScreen extends StatefulWidget {
  final DocumentSnapshot module;
  final DocumentReference courseReference;
  final bool isEnrolled;
  final bool isCompleted;

  ModuleDetailScreen({
    required this.module,
    required this.courseReference,
    required this.isEnrolled,
    required this.isCompleted,
  });

  @override
  _ModuleDetailScreenState createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  var user = FirebaseAuth.instance.currentUser;
  late bool isCompleted = widget.isCompleted;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('Initializing video player...');
      _videoPlayerController =
          VideoPlayerController.network(widget.module['videoURL']);

      await _videoPlayerController!.initialize();

      print('Video player initialized successfully.');
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoInitialize: true,
        looping: false,
        aspectRatio: 16 / 9, // Adjust as per your video aspect ratio
      );

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> markModule(bool completed) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = user!.uid;
    final courseReference = widget.courseReference;
    final moduleId = widget.module.id;

    try {
      final enrolledCourseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('enrolledCourses')
          .where('enrolled', isEqualTo: courseReference)
          .get();

      if (enrolledCourseSnapshot.docs.isNotEmpty) {
        final enrolledCourseDoc = enrolledCourseSnapshot.docs.first;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('enrolledCourses')
            .doc(enrolledCourseDoc.id)
            .collection('completedModules')
            .doc(moduleId)
            .set({
          'completed': completed,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Module marked as ${completed ? 'completed' : 'incomplete'}')),
        );

        setState(() {
          isCompleted = completed;
        });

        // Return true to indicate module status changed
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update module status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.module['name']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.isEnrolled)
                  ElevatedButton(
                    onPressed: () => markModule(!isCompleted),
                    child: Text(isCompleted
                        ? 'Mark as Incomplete'
                        : 'Mark as Completed'),
                  ),
              ],
            ),
            Flexible(
              child: Text(
                'Module ${widget.module['topic']}: ${widget.module['name']}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Video:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(child: Text('Failed to load video'))
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _chewieController != null &&
                                _chewieController!
                                    .videoPlayerController.value.isInitialized
                            ? Chewie(controller: _chewieController!)
                            : Center(child: CircularProgressIndicator()),
                      ),
          ],
        ),
      ),
    );
  }
}
