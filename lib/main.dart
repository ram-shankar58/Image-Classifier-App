import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageViewer(),
    );
  }
}

class ImageViewer extends StatefulWidget {
  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  File? _latestImageFile;

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
  }

  // Check for storage permissions and load the latest image
  Future<void> _checkStoragePermission() async {
    // Request MANAGE_EXTERNAL_STORAGE permission for Android 11+
    if (await Permission.manageExternalStorage.isDenied) {
      PermissionStatus status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        _loadLatestImage();
      } else {
        print("Storage permission denied.");
      }
    } else if (await Permission.storage.isDenied) {
      // For Android < 11, request regular storage permission
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        _loadLatestImage();
      } else {
        print("Storage permission denied.");
      }
    } else {
      // Permission already granted
      _loadLatestImage();
    }
  }

  // Load the latest image from the 'HIKMICRO Viewer' folder
  Future<void> _loadLatestImage() async {
    final directory = Directory('/storage/emulated/0/Pictures/HIKMICRO Viewer');
    if (directory.existsSync()) {
      final List<FileSystemEntity> files = directory.listSync();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (files.isNotEmpty && files.first is File) {
        setState(() {
          _latestImageFile = files.first as File;
        });
      } else {
        print("No image files found.");
      }
    } else {
      print("Directory does not exist.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Latest Image Viewer'),
      ),
      body: Center(
        child: _latestImageFile != null
            ? Image.file(_latestImageFile!)
            : Text('No image found.'),
      ),
    );
  }
}
