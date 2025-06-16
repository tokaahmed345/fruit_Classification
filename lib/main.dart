import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String id = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  XFile? _image;
  File? file;
  final ImagePicker _picker = ImagePicker();
  var _recognitions;
  String label = '';
  String confidence = '';

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = image;
          file = File(image.path);
        });
        detectImage(file!);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }


  Future<void> detectImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _recognitions = recognitions;
      if (recognitions != null && recognitions.isNotEmpty) {
        label = recognitions[0]['label'];
        confidence = (recognitions[0]['confidence'] * 100).toStringAsFixed(2) + "%";
      }
    });
  }
//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Image Classification",
          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff1a5a99),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            _image == null ? const CustomDottedContainer() : Image.file(file!, height: 200),
            const SizedBox(height: 30),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xff1a5a99),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: Colors.white, size: 40),
                    SizedBox(width: 7),
                    Text("Select Image", style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (label.isNotEmpty && confidence.isNotEmpty)
              Content(label: label, confidence: confidence),
          ],
        ),
      ),
    );
  }
}

class Content extends StatelessWidget {
  final String label;
  final String confidence;

  const Content({
    super.key,
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: "Class: ",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              TextSpan(
                text: label,
                style: const TextStyle(fontSize: 27, color: Color(0xff1a5a99), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: "Prediction: ",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              TextSpan(
                text: confidence,
                style: const TextStyle(fontSize: 25, color: Color(0xff1a5a99), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomDottedContainer extends StatelessWidget {
  const CustomDottedContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: Colors.blue,
      dashPattern: [10, 5],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      strokeWidth: 2,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: Colors.blue.withOpacity(.5),
            size: 80,
          ),
        ),
      ),
    );
  }
}
