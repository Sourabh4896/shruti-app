import 'dart:typed_data';
import 'dart:io';
import 'dart:convert'; // For Base64 encoding
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  String? _imageText; // To hold the image as text (Base64)

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Function to convert image to Base64 text
  Future<String> _convertImageToBase64(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes(); // Read the image as bytes
    return base64Encode(bytes); // Convert bytes to Base64 string
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Camera with Image as Text"),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Camera Preview
                  Container(
                    height: 200,
                    child: CameraPreview(_controller),
                  ),

                  // Display Image as Text
                  if (_imageText != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Image as Base64 Text:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey[200],
                            child: Text(
                              _imageText!,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Placeholder if no image is captured yet
                  if (_imageText == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No image captured yet."),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            // Capture the image
            final image = await _controller.takePicture();
            final String imagePath = image.path;

            // Convert image to Base64
            final String base64Image = await _convertImageToBase64(imagePath);

            setState(() {
              _imageText = base64Image; // Save Base64 text to state
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Image captured and displayed as text!"),
            ));
          } catch (e) {
            print("Error capturing image: $e");
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
