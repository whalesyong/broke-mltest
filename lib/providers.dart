import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mltest/main.dart';
import 'package:path/path.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';


class TextClassifier {
  late Interpreter _interpreter;
  late HttpsCallable _preprocessFunction;

  Future<void> loadModel() async {
    // Load the TensorFlow Lite model
    _interpreter = await Interpreter.fromAsset('lib/assets/text_classification_model.tflite');

    // Initialize the Cloud Function
    //_preprocessFunction = FirebaseFunctions.instance.httpsCallable('preprocess_text');
  }


Future<List> predict(String text) async {
  final url = Uri.parse('https://us-central1-broke-uibranch.cloudfunctions.net/preprocess_text');
  
  final headers = {
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'data': {'text' : text}
    });

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: body
    );

    print( 'encoded text: $body');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      var sequence = result['result'];
      print('Preprocessed sequence: ${sequence['sequence']}');

      // Ensure the sequence is a List<int> 
      List<int> input = List<int>.from(sequence['sequence']);

      //get input/output tensors 
      var inputTensor = _interpreter.getInputTensors();
      var outputTensor = _interpreter.getOutputTensors();
      print('Input tensor shape: ${inputTensor[0].shape}');
      print('Output tensor shape: ${outputTensor[0].shape}');


      // Prepare input tensor
      var inputBuffer = Float32List(100);
      for (var i = 0; i < input.length; i++) {
        inputBuffer[i] = input[i].toDouble();
      }
       var newInputBuffer = [inputBuffer] ;
      

      // Prepare output tensor
      //var outputBuffer = List.generate(6, (_)=> List<double>.filled(3,0));
      var outputBuffer = List<double>.filled(3, 0.0).reshape([1,3]);  // Replace zeros with initial values if needed

      // Run inference
      try{
        _interpreter.run(newInputBuffer, outputBuffer);
      } catch(e){
        print('Error during inference: $e');
        
        rethrow;
      }

      return outputBuffer.toList();
    } else {
      // Request failed 
      print('Failed with status code: ${response.statusCode}');
      print('Response: ${response.body}');
      throw Exception('Failed to preprocess text');
    }
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
  }
}

class MyMLTextRecognizer{

  
  static Future<RecognizedText> getRecognisedText(InputImage inputImage) async {
    TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    //runtime error if no image
    final recognisedText = await _textRecognizer.processImage(inputImage);
    return recognisedText;
  }

  static void printTextToConsole(InputImage inputImage) async {
   RecognizedText processedText = await getRecognisedText(inputImage);
   print(processedText.text);
  }


  static List<List<TextElement>>  reorganiseText(RecognizedText recognisedText){
    //take text as input: run organisation algo to reorder the text elements
    List<TextElement> textElementList = [];
    for(TextBlock block in recognisedText.blocks){
      for(TextLine line in block.lines){
        textElementList.addAll(line.elements);
      }
    }
    //Sorts the elements by their Y-Coordinate 
    textElementList.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
   
   

    List<List<TextElement>> reorganisedList = [];
    List<TextElement> currentLine = [];
    for (int i = 0; i < textElementList.length; i++) {
    if (currentLine.isEmpty || _isSameLine(currentLine.last, textElementList[i])) {
      currentLine.add(textElementList[i]);
    } else {
      // Current element is not on the same line
      currentLine.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      reorganisedList.add(List.from(currentLine)); // Create a new list from currentLine
      currentLine = [textElementList[i]]; // Start a new line with the current element
    }
  }

  // Add the last line if it's not empty
  if (currentLine.isNotEmpty) {
    currentLine.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    reorganisedList.add(List.from(currentLine));
  }
    return reorganisedList;
  }

  static String returnReorganisedText(List<List<TextElement>> reorganisedText){
    String result = reorganisedText.map((line){
      return line.map((element) => element.text).join(' ');
    }).join('\n');

    return result;
  }

 
  static bool _isSameLine(TextElement firstElement, TextElement secondElement){
    double vertDiff = (firstElement.boundingBox.top - secondElement.boundingBox.top).abs(); 
    double height = (firstElement.boundingBox.height + secondElement.boundingBox.height) ;

    //not the same line IFF vertical coord diff > 0.4* word height
    if(vertDiff < height *0.35){
      return true;
    } 
    return false;
  }

}




class TextRecognitionPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final ui.Image image;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  TextRecognitionPainter({required this.recognizedText, required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawImage(image, Offset.zero, Paint());
    int i = 0;
    for (TextBlock block in recognizedText.blocks) {
      paint.color = Colors.red;
      canvas.drawRect(block.boundingBox, paint);

      for (TextLine line in block.lines) {
        paint.color = Colors.orange;
        canvas.drawRect(line.boundingBox, paint);

        for (TextElement element in line.elements) {
          paint.color = Colors.green;
          canvas.drawRect(element.boundingBox, paint);
          textPainter.text = TextSpan(
            text: (i+1).toString(),
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)
          );
          textPainter.layout();
          textPainter.paint(canvas, element.boundingBox.topLeft);
          i++;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}