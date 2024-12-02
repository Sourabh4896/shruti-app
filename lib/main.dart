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

  File? _capturedImage; // Store captured image file
  String? _imageText; // Store shortened Base64 string of image

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

  /// Convert image file to Base64 string
  Future<String> _convertImageToBase64(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Shorten the Base64 string for display
  String _shortenBase64(String base64String, {int length = 50}) {
    if (base64String.length > length) {
      return "${base64String.substring(0, length)}...${base64String.substring(base64String.length - length)}";
    }
    return base64String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture and Display Image"),
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
                  if (_capturedImage == null)
                    Container(
                      height: 200,
                      child: CameraPreview(_controller),
                    ),

                  // Display Captured Image
                  if (_capturedImage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text(
                            "Captured Image:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Image.file(
                            _capturedImage!,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),

                  // Display Image as Shortened Text
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

                  // Placeholder for no captured image
                  if (_capturedImage == null)
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

            // Convert image to Base64 and shorten it
            final String base64Image = await _convertImageToBase64(imagePath);
            final String shortenedBase64 = _shortenBase64(base64Image);
  
            setState(() {
              _capturedImage = File(imagePath); // Save captured image file
              _imageText = shortenedBase64; // Save shortened Base64 string
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Image captured and displayed!"),
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
