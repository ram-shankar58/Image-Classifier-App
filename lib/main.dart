import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  img.Image? image;
  Iterable<MapEntry<String, double>>? results;
  String? imagePath;

  @override
  void initState() {
    super.initState();
  }

  void cleanResult() {
    imagePath = null;
    image = null;
    results = null;
    setState(() {});
  }

  /// Function to launch the HikMicro app
  Future<void> launchHikMicroApp() async {
    const packageName = 'com.hikvision.thermalGoogle'; // Replace with the actual HikMicro package name

    // Check if the HikMicro app can be launched
    final bool canLaunchApp = await canLaunchUrl(Uri.parse("market://launch?id=com.hikvision.thermalGoogle"));

    if (canLaunchApp) {
      // Launch the HikMicro app
      await launchUrl(Uri.parse("market://launch?id=com.hikvision.thermalGoogle"));
    } else {
      // If the app is not installed or can't be launched, show an error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('HikMicro app is not installed or cannot be opened.'),
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

            // Top Image Display Section (if image is available)
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

            // Padding for the action button at the bottom
            const SizedBox(height: 50), // Adds space before the button

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

            const SizedBox(height: 40), // Adds more space after the button
          ],
        ),
      ),
    );
  }
}
