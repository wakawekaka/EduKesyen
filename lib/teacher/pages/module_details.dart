import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ModuleDetailsPage extends StatefulWidget {
  final DocumentSnapshot module;

  ModuleDetailsPage({required this.module});

  @override
  _ModuleDetailsPageState createState() => _ModuleDetailsPageState();
}

class _ModuleDetailsPageState extends State<ModuleDetailsPage> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.module['videoURL']);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      looping: false,
      aspectRatio: 16 / 9, // Adjust as per your video aspect ratio
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Module Details'),
      ),
      body: Center(
        child: Chewie(controller: _chewieController),
      ),
    );
  }
}
