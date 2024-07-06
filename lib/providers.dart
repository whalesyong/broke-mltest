import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitProvider extends ChangeNotifier{

  
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
            style: TextStyle(color: Colors.black)
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