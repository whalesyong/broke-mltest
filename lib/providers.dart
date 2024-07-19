import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mltest/main.dart';
import 'package:path/path.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RegExProcessor {}

class TextClassifier {
  late Interpreter _interpreter;
  late HttpsCallable _preprocessFunction;

  Future<void> loadModel() async {
    // Load the TensorFlow Lite model
    _interpreter = await Interpreter.fromAsset(
        'lib/assets/text_classification_model.tflite');

    // Initialize the Cloud Function
    //_preprocessFunction = FirebaseFunctions.instance.httpsCallable('preprocess_text');
  }

  Future<List> predict(String text) async {
    final url = Uri.parse(
        'https://us-central1-broke-uibranch.cloudfunctions.net/preprocess_text');

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'data': {'text': text}
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('encoded text: $body');

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
        var newInputBuffer = [inputBuffer];

        // Prepare output tensor
        //var outputBuffer = List.generate(6, (_)=> List<double>.filled(3,0));
        var outputBuffer = List<double>.filled(3, 0.0)
            .reshape([1, 3]); // Replace zeros with initial values if needed

        // Run inference
        try {
          _interpreter.run(newInputBuffer, outputBuffer);
        } catch (e) {
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

class MyMLTextRecognizer {
  static Future<RecognizedText> getRecognisedText(InputImage inputImage) async {
    TextRecognizer _textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    //runtime error if no image
    final recognisedText = await _textRecognizer.processImage(inputImage);
    return recognisedText;
  }

  static void printTextToConsole(InputImage inputImage) async {
    RecognizedText processedText = await getRecognisedText(inputImage);
    print(processedText.text);
  }

  static List<List<TextElement>> reorganiseText(RecognizedText recognisedText) {
    //take text as input: run organisation algo to reorder the text elements
    List<TextElement> textElementList = [];
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        textElementList.addAll(line.elements);
      }
    }
    //Sorts the elements by their Y-Coordinate
    textElementList
        .sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<List<TextElement>> reorganisedList = [];
    List<TextElement> currentLine = [];
    for (int i = 0; i < textElementList.length; i++) {
      if (currentLine.isEmpty ||
          _isSameLine(currentLine.last, textElementList[i])) {
        currentLine.add(textElementList[i]);
      } else {
        // Current element is not on the same line
        currentLine
            .sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        reorganisedList
            .add(List.from(currentLine)); // Create a new list from currentLine
        currentLine = [
          textElementList[i]
        ]; // Start a new line with the current element
      }
    }

    // Add the last line if it's not empty
    if (currentLine.isNotEmpty) {
      currentLine
          .sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      reorganisedList.add(List.from(currentLine));
    }
    return reorganisedList;
  }

  static String returnReorganisedText(List<List<TextElement>> reorganisedText) {
    String result = reorganisedText.map((line) {
      return line.map((element) => element.text).join(' ');
    }).join('\n');

    return result;
  }

  static bool _isSameLine(TextElement firstElement, TextElement secondElement) {
    double vertDiff =
        (firstElement.boundingBox.top - secondElement.boundingBox.top).abs();
    double height =
        (firstElement.boundingBox.height + secondElement.boundingBox.height);

    //not the same line IFF vertical coord diff > 0.4* word height
    if (vertDiff < height * 0.35) {
      return true;
    }
    return false;
  }
}

class TextRecognitionPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final ui.Image image;
  final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
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
              text: (i + 1).toString(),
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12));
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

class myRegExpClass {
  static List<String> extractFirstThreeWords(String input) {
    final nameRegex = RegExp(r'^\s*(\S+)\s+(\S+)\s+(\S+)');
    final match = nameRegex.firstMatch(input);

    if (match != null) {
      return [
        match.group(1) ?? '',
        match.group(2) ?? '',
        match.group(3) ?? '',
      ];
    } else {
      return [];
    }
  }

  static String extractMostRecentDate(String input) {
    final datePatterns = [
      r'\b(\d{2}/\d{2}/\d{2})\b',
      r'\b(\d{2}/\d{2}/\d{4})\b',
      r'\b(\d{4}/\d{2}/\d{2})\b',
      r'\b(\d{4}-\d{2}-\d{2})\b',
      r'\b(\d{2}-\d{2}-\d{4})\b',
      r'\b(\d{6})\b',
    ];

    final dateFormats = [
      'dd/MM/yy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'yyMMdd',
      'ddMMyy',
    ];

    List<DateTime> dates = [];

    for (int i = 0; i < datePatterns.length; i++) {
      final regex = RegExp(datePatterns[i]);
      for (var match in regex.allMatches(input)) {
        try {
          if (i < dateFormats.length - 1) {
            dates.add(DateFormat(dateFormats[i]).parse(match.group(1)!));
          } else {
            // For 6-digit formats, try both yyMMdd and ddMMyy
            try {
              dates.add(DateFormat(dateFormats[dateFormats.length - 2])
                  .parse(match.group(1)!));
            } catch (e) {
              dates.add(DateFormat(dateFormats[dateFormats.length - 1])
                  .parse(match.group(1)!));
            }
          }
        } catch (e) {
          // Ignore invalid dates
        }
      }
    }

    DateTime resultDate;
    if (dates.isEmpty) {
      // If no valid dates found, use the current date
      resultDate = DateTime.now();
    } else {
      // Sort dates and find the most recent one
      dates.sort((a, b) => b.compareTo(a));
      resultDate = dates.reduce((a, b) => a.difference(DateTime.now()).abs() <
              b.difference(DateTime.now()).abs()
          ? a
          : b);
    }

    return DateFormat('yyyy-MM-dd').format(resultDate);
  }

  static String findLargestAmount(String input) {
    // Convert input to lowercase for case-insensitive matching
    input = input.toLowerCase();

    // Regex for finding numbers after "$"
    final dollarRegex = RegExp(r'\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)');

    // Regex for finding numbers after "visa" or "master"
    final cardRegex = RegExp(r'(visa|master).*?(\d+(?:,\d{3})*(?:\.\d{2})?)');

    // Regex for finding numbers after "total"
    final totalRegex = RegExp(r'total.*?(\d+(?:,\d{3})*(?:\.\d{2})?)');

    double largestAmount = 0.0;

    // Function to parse amount string to double
    double parseAmount(String amount) {
      return double.parse(amount.replaceAll(',', ''));
    }

    // Check for dollar amounts first
    var matches = dollarRegex.allMatches(input);
    if (matches.isNotEmpty) {
      for (var match in matches) {
        double amount = parseAmount(match.group(1)!);
        if (amount > largestAmount) {
          largestAmount = amount;
        }
      }
    } else {
      // If no dollar amounts, check for card amounts
      matches = cardRegex.allMatches(input);
      if (matches.isNotEmpty) {
        for (var match in matches) {
          double amount = parseAmount(match.group(2)!);
          if (amount > largestAmount) {
            largestAmount = amount;
          }
        }
      } else {
        // If no card amounts, check for total amounts
        matches = totalRegex.allMatches(input);
        for (var match in matches) {
          double amount = parseAmount(match.group(1)!);
          if (amount > largestAmount) {
            largestAmount = amount;
          }
        }
      }
    }

    return largestAmount > 0
        ? largestAmount.toStringAsFixed(2)
        : "No amount found";
  }
}
