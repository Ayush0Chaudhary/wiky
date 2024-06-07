import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart.dart';
import 'system_prompt.dart';
import 'dart:convert';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wiky',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Timer _timer;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  Map<String, dynamic> analysisMap = {};

  bool stop = false;
  bool showCamPreview = true;
  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env["APIKEY"];
    if (apiKey != null) {
      _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey,
          generationConfig:
              GenerationConfig(responseSchema: Schema(SchemaType.object)));
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
      appBar: AppBar(
        title: const Text(
          'Wiky : Will it kill you',
          style: TextStyle(color: Colors.white, fontFamily: 'mukta'),
        ),
        backgroundColor: Colors.black,
      ),
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
          TextPart(prompt),
          DataPart('image/jpeg', imageUint),
        ])
      ];

      var response = await _model.generateContent(content);
      String responseStr = response.candidates.map((e) => e.text).join('');
      Map<String, dynamic> responseMap =
          jsonDecode(responseStr.substring(7, responseStr.length - 3));
      showModalBottomSheet(
          context: context,
          builder: (builder) {
            return Container(
                height: 400,
                width: double.infinity,
                decoration: const BoxDecoration(),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            analysisMap['analysis'] ?? 'No analysis found',
                            style: const TextStyle(
                                fontSize: 14, fontFamily: 'mukta'),
                          ),
                        ),
                      ),
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                          child: SizedBox(
                            height: 300,
                            width: 300,
                            child: PieChartWidget(analysisMap['details'] ?? {}),
                          )),
                    ],
                  ),
                ));
          });
      setState(() {
        analysisMap = responseMap;
        stop = true;
      });
    } catch (e) {
      print(e);
    }
  }
}
