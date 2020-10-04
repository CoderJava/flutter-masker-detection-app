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
  bool _loading;
  File _image;
  List _outputs;

  @override
  void initState() {
    _loading = true;
    loadModel().then((value) {
      setState(() => _loading = false);
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
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null ? Container() : Image.file(_image),
                  SizedBox(height: 20),
                  _outputs != null
                      ? Text(
                          '${_outputs[0]['label']}'.replaceAll(RegExp(r'[0-9]'), ''),
                          style: TextStyle(
                            fontSize: 20,
                            background: Paint()..color = Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text('Classification waiting'),
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
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(_image);
  }

  void classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
      debugPrint('outputs: $_outputs');
    });
  }
}
