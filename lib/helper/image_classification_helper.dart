/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassificationHelper {
  static const modelPath = 'assets/model.tflite';
  static const labelsPath = 'assets/labels.txt';

  late final Interpreter interpreter;
  late final List<String> labels;
  late Tensor inputTensor;
  late Tensor outputTensor;

  // Load model
  Future<void> _loadModel() async {
    // final options = InterpreterOptions();

    // Use XNNPACK Delegate
    // if (Platform.isAndroid) {
    //   options.addDelegate(XNNPackDelegate());
    // }

    // Use GPU Delegate
    // doesn't work on emulator
    // if (Platform.isAndroid) {
    //   options.addDelegate(GpuDelegateV2());
    // }

    // Use Metal Delegate
    // if (Platform.isIOS) {
    //   options.addDelegate(GpuDelegate());
    // }

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelPath);
    // Get tensor input shape [1, 224, 224, 3]
    inputTensor = interpreter.getInputTensors().first;
    // Get tensor output shape [1, 1000]
    outputTensor = interpreter.getOutputTensors().first;

    log('input shape $inputTensor');
    log('ouput shape $outputTensor');
    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    labels = labelTxt.split('\n');
  }

  Future<void> initHelper() async {
    _loadLabels();
    _loadModel();
  }

  // inference still image
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
          final pixel = imageInput.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1,
            (pixel.g / 127.5) - 1,
            (pixel.b / 127.5) - 1,];
        },
      ),
    );

    // Set tensors shape
    final input = [imageMatrix];
    final output = List.filled(1*1000, 0).reshape([1,1000]);
    // Run inference;
    interpreter.run(input, output);
    // Get first output tensor
    final result = output.first;
    // Set classification map {label: points}
    var classification = <String, double>{};
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
