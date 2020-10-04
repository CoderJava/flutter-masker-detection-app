import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Masker Detection',
      home: HomePage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var isLoading = false;
  File fileImage;
  final listOutputs = [];

  @override
  void initState() {
    isLoading = true;
    loadModel().then((value) {
      setState(() => isLoading = false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flutter Masker Detection',
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  fileImage == null ? Container() : Image.file(fileImage),
                  SizedBox(height: 16),
                  listOutputs == null || listOutputs.isEmpty
                      ? Text('Upload your image')
                      : Text(
                          '${listOutputs[0]['label']}'.replaceAll(RegExp(r'[0-9]'), ''),
                          style: TextStyle(
                            fontSize: 20,
                            background: Paint()..color = Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.camera),
            tooltip: 'Take Picture From Camera',
            onPressed: () => pickImage(ImageSource.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            child: Icon(Icons.image),
            tooltip: 'Take Picture From Gallery',
            onPressed: () => pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  void pickImage(ImageSource imageSource) async {
    var image = await ImagePicker().getImage(source: imageSource);
    if (image == null) {
      return null;
    }
    setState(() {
      isLoading = true;
      fileImage = File(image.path);
    });
    processImage(fileImage);
  }

  void processImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      isLoading = false;
      listOutputs.clear();
      listOutputs.addAll(output);
      debugPrint('outputs: $listOutputs');
    });
  }
}
