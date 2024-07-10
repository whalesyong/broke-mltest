import 'dart:ui' as ui;


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart';


class RegExProcessor{
   
}

class MyMLKit{

  
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
    for (TextElement element in textElementList) {
    //print(element.text);
    }
   

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

 
  static bool _isSameLine(TextElement firstElement, TextElement secondElement){
    double vertDiff = (firstElement.boundingBox.top - secondElement.boundingBox.top).abs(); 
    double height = (firstElement.boundingBox.height + secondElement.boundingBox.height) ;

    //not the same line IFF vertical coord diff > 0.4* word height
    if(vertDiff < height *0.2){
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