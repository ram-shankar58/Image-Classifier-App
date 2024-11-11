
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class Sensor{
  static const modelPath = 'assets/'; //MOdel path for the spectral triad sensor traini
  static const labelsPath = 'assets/labels.txt'; //for the same
  late final Interpreter  interpreter;
  late final List<String> labels;
  late Tensor inputTensor;
  late Tensor outputTensor;

  Future<void> _loadModel() async{
    interpreter = await Interpreter.fromAsset(modelPath);
    inputTensor = interpreter.getInputTensors().first;
    outputTensor = interpreter.getOutputTensors().first;
    log('input shate $inputTensor');
    log('Output shape $outputTensor');
    log('Interpreter loaded successfully');

    Future<void> _loadLabels() async{
      final labelTxt = await rootBundle.loadString(labelsPath);
      labels=labelTxt.split('\n');
    }

    Future<void> initHelper() async{
      _loadLabels();
      _loadModel();
    }
    Future<Map<String, double>> inferenceImage(Image image) async { 
    // resize original image to match model shape.
    Image imageInput = copyResize(
      image,
      width: inputTensor.shape[1],
      height: inputTensor.shape[2],
    );

    // RGB value of each pixel in image
    final imageMatrix = List.generate(
      imageInput.height,
          (y) => List.generate(
        imageInput.width,
            (x) {
          final pixel = imageInput.getPixel(x, y);   //see if you need to do normalisation of image here 
          return [
            (pixel.r),
            (pixel.g),
            (pixel.b ),];
        },
      ),
    );

    // Set tensors shape
    final input = [imageMatrix];
    final output = List.filled(1*2, 0).reshape([1,2]);
    // Run inference;
    interpreter.run(input, output);
    // Get first output tensor
    final result = output.first;
    // Set classification map {label: points}
    var classification = <String, double>{};     //change classification to stirg alone!
    for (var i = 0; i < result.length; i++) {
      if (result[i] != 0) {
        // Set label: points
        classification[labels[i]] =
            result[i].toDouble();
      }
    }
    return classification;
  }
}
}