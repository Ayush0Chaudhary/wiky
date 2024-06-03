import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wiky',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Timer _timer;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  String analysisText = 'Point the Camera toward the label';
  bool stop = false;
  bool showCamPreview = true;
  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env["APIKEY"];
    if(apiKey != null) {
      _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey);
      _chat = _model.startChat();

      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      _initializeControllerFuture = _controller.initialize().then((_) {
        // Capture an image as soon as the camera feed is open
        // _captureAndSendImage();
        // Set up a timer to capture and send images every second
        // _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        //   if (!stop) {
        //     _captureAndSendImage();
        //   }
        // });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinkit = SpinKitFadingCube(
      size: 80,
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: index % 4 == 0
                ? Colors.purple
                : index % 4 == 1
                    ? Colors.deepPurple
                    : (index % 4 == 2)
                        ? Colors.purple
                        : Colors.deepPurple,
          ),
        );
      },
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Wiky : Will it kill you', style: TextStyle(color: Colors.white, fontFamily: 'mukta'),), backgroundColor: Colors.black,),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              showCamPreview) {
            return CameraPreview(_controller);
            // return spinkit;
          } else {
            return Center(child: spinkit);
          }
        },
      ),
      bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: IconButton(
            icon: const Icon(
              size: 40,
              Icons.camera,
              color: Colors.black,
            ),
            onPressed: () async {
              await _captureAndSendImage();
            },
          )),
    );
  }

  Future<void> _captureAndSendImage() async {
    try {
      // Ensure the camera is initialized
      await _initializeControllerFuture;
      setState(() {
        showCamPreview = false;
      });
      // Attempt to take a picture and get the file where it was saved
      final image = await _controller.takePicture();
      print('Got an image ^^^^^^^^^^^^^^^^^^^^');
      // Send the image to the API
      await _sendImageToApi(image);
      setState(() {
        showCamPreview = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _sendImageToApi(XFile image) async {
    try {
      Uint8List imageUint = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            // NOTE: ADD command here
              'Tell me by analyzing the food label you see if the packed product is ok for consuming'),
          // The only accepted mime types are image/*.
          DataPart('image/jpeg', imageUint),
        ])
      ];
      var response = await _model.generateContent(content);
      showModalBottomSheet(
          context: context,
          builder: (builder) {
            return Container(
              height: 400,
              width: double.infinity,
              decoration: const BoxDecoration(),
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        analysisText,
                        style: const TextStyle(fontSize: 14, fontFamily: 'mukta'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
      setState(() {
        analysisText = response.text ?? "No Response from Gemini";
        stop = true;
      });
    } catch (e) {
      print(e);
    }
  }
}
