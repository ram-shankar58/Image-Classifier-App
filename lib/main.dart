import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'helper/image_classification_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 22, 184, 233)),
      ),
      home: const MyHomePage(title: ''),
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
  ImageClassificationHelper? imageClassificationHelper;
  final imagePicker = ImagePicker();
  String? imagePath;
  XFile? imageFile;
  img.Image? image;
  Map<String, double>? classification;
  Iterable<MapEntry<String, double>>? results;
  File? _latestImageFile;
  bool launchedHikMicro = false;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    WidgetsBinding.instance.addObserver(this);
    _checkStoragePermission();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && launchedHikMicro) {
      _loadLatestImage();
    }
  }

  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    results = null;
    setState(() {});
  }

  pickImageFromGallery() async {
    cleanResult();
    final result = await imagePicker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      imagePath = result.path;
      setState(() {});
      processImage();
    }
  }

  Future<void> processImage() async {
    if (imagePath != null) {
      final imageData = File(imagePath!).readAsBytesSync();
      image = img.decodeImage(imageData);
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);
      results = (classification!.entries.toList()
            ..sort(
              (a, b) => a.value.compareTo(b.value),
            ))
          .reversed
          .take(3);
      setState(() {});
    }
  }

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
        processImage();
      } else {
        _showErrorDialog('No image files found in the HIKMICRO Viewer folder.');
      }
    } else {
      _showErrorDialog('HIKMICRO Viewer directory does not exist.');
    }
  }

  Future<void> launchHikMicroApp() async {
    const packageName = 'com.hikvision.thermalGoogle'; // Replace with actual HikMicro package name

    final bool canLaunchApp = await canLaunchUrl(Uri.parse("market://launch?id=$packageName"));

    if (canLaunchApp) {
      setState(() {
        launchedHikMicro = true;
      });
      await launchUrl(Uri.parse("market://launch?id=$packageName"));
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
            // Welcome Text
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

            // Image Display Section
            if (image != null)
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
                          File(imagePath!),
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

            // Buttons: Load from Gallery and Load Latest Image from HikMicro
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Load Image from Gallery
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: pickImageFromGallery,
                    child: const Text(
                      'Select from Gallery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Load Latest Image from HikMicro
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: launchHikMicroApp,
                    child: const Text(
                      'Load from HikMicro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
