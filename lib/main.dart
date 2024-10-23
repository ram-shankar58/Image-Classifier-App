import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // for picking images
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classification',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 22, 184, 233)),
      ),
      home: const MyHomePage(title: 'Image Classification App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  img.Image? image;
  Iterable<MapEntry<String, double>>? results;
  String? imagePath;
  File? _latestImageFile;
  bool launchedHikMicro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStoragePermission(); // Check permissions when initializing
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && launchedHikMicro) {
      // When returning from the HikMicro app, load the latest image from the directory
      _loadLatestImage();
    }
  }

  // Check for storage permissions
  Future<void> _checkStoragePermission() async {
    if (await Permission.manageExternalStorage.isDenied) {
      PermissionStatus status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        _loadLatestImage();
      } else {
        print("Storage permission denied.");
      }
    } else if (await Permission.storage.isDenied) {
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        _loadLatestImage();
      } else {
        print("Storage permission denied.");
      }
    } else {
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
          imagePath = _latestImageFile!.path;
          image = img.decodeImage(File(imagePath!).readAsBytesSync());
        });

        // Navigate to the classification page with the loaded image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassificationPage(imagePath: imagePath!),
          ),
        );
      } else {
        print("No image files found.");
        _showErrorDialog('No image files found in the HIKMICRO Viewer folder.');
      }
    } else {
      print("Directory does not exist.");
      _showErrorDialog('HIKMICRO Viewer directory does not exist.');
    }
  }

  /// Function to launch the HikMicro app
  Future<void> launchHikMicroApp() async {
    const packageName = 'com.hikvision.thermalGoogle'; // Replace with the actual HikMicro package name

    final bool canLaunchApp = await canLaunchUrl(Uri.parse("market://launch?id=com.hikvision.thermalGoogle"));

    if (canLaunchApp) {
      setState(() {
        launchedHikMicro = true;
      });
      await launchUrl(Uri.parse("market://launch?id=com.hikvision.thermalGoogle"));
    } else {
      _showErrorDialog('HikMicro app is not installed or cannot be opened.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topResult = results?.isNotEmpty == true ? results!.first.key : 'No result';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'Welcome to the Image Classification App!',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            if (_latestImageFile != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_latestImageFile!.path),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Top Classification: $topResult',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00C853),
                      Color(0xFF64DD17),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: launchHikMicroApp, // Open the HikMicro app
                  child: const Text(
                    'Open HikMicro App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ClassificationPage extends StatelessWidget {
  final String imagePath;

  const ClassificationPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Classification Result'),
      ),
      body: Center(
        child: Column(
          children: [
            Image.file(File(imagePath)),
            const SizedBox(height: 20),
            Text(
              'Model Running on the Selected Image',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Add your logic to run the classification model on the image
          ],
        ),
      ),
    );
  }
}
