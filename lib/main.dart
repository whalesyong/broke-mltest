import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mltest/firebase_options.dart';
import 'package:mltest/providers.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

    runApp(CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class HomePage extends StatelessWidget {
  
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Home'),),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(onPressed:(){
              Navigator.push(context, MaterialPageRoute(builder: (_){
                return const CameraScreen();
              }));
            } , child: const Text('Take a Picture')),

            //do nothing for now 
            ElevatedButton(onPressed: (){}, child: const Text('Upload Image')), SizedBox(height: 30,),

            //from image picker library
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return GalleryImagePicker();
              }));
            } , 
              child: Text('Image Picker : pick an image'))
          ],
        ),
      ),
    );
  }
}

class GalleryImagePicker extends StatefulWidget {
  const GalleryImagePicker({super.key});

  @override
  State<GalleryImagePicker> createState() => _GalleryImagePickerState();
}

class _GalleryImagePickerState extends State<GalleryImagePicker> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool hasImageLoaded = false;

  Future<void> _loadData() async {
     final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);

      if( pickedImage != null){
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:<Widget> [
              _image == null 
                ? const Text('No image selected')
                : Image.file(_image!),
              const SizedBox(height: 30,),
              ElevatedButton(onPressed: (){
                _loadData();
                hasImageLoaded = true;
              }, child: Text('Choose image')),
        
              _image == null
              ? ElevatedButton(onPressed: (){}, child: Text('No image to process') )
              : ElevatedButton(onPressed:()=> Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) => DisplayPictureScreen(imagePath: _image!.path))), 
              child: Text('Process Image'))
            ],
          ),
        ),
      ),
    );
  }
}




class CameraScreen extends StatefulWidget {

  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

 CameraController? _controller;
  Future<void>? _initControllerFuture;

  @override
  void initState() {
    super.initState();
    initCamera();
  }
  
  @override
  void dispose() {

    super.dispose();
    _controller?.dispose();
  }

  void initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
     _controller = CameraController(firstCamera, ResolutionPreset.medium);
    _initControllerFuture = _controller!.initialize();
    
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initControllerFuture;
            final image = await _controller!.takePicture();
            if(!context.mounted) return;
            await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DisplayPictureScreen(imagePath: image.path)));
          } catch (e){
            print(e);
          }
        },
      ),
      appBar: AppBar(
        
        title: const Text('Camera'),
        leading:  IconButton(icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initControllerFuture,
        builder: (context, snapshot) {
          if( snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(),);
          } else {
            return _controller != null
            ? CameraPreview(_controller!)
            : const Center(child: Center(child: CircularProgressIndicator()),);
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  
  final String imagePath;
  DisplayPictureScreen({super.key, required this.imagePath});
 


  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  InputImage? _inputImage;
  TextRecognizer? _textRecognizer;
  bool _isLoading = true;
  late final RecognizedText recognisedText;
  

  @override 
  void dispose() {
    super.dispose();
    _textRecognizer!.close();
  }


  Future<void> initImageProcess() async {
    _inputImage = InputImage.fromFilePath(widget.imagePath);
    recognisedText = await MyMLTextRecognizer.getRecognisedText(_inputImage!);

    MyMLTextRecognizer.printTextToConsole;
    setState(() {
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            
             Image.file(File(widget.imagePath)),
          
             
             ElevatedButton(
              onPressed: () async {
                await initImageProcess();
                
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => TextRecognitionVisualization(
                  recognizedText: recognisedText, imagePath: widget.imagePath)));
                            
              }, 
              child: Text('Process Text'))
          ],
        ),
      ),
    );
  }
}


class TextRecognitionVisualization extends StatelessWidget {
  final RecognizedText recognizedText;
  final String imagePath;

  const TextRecognitionVisualization({
    Key? key, 
    required this.recognizedText, 
    required this.imagePath
  }) : super(key: key);

  Future<ui.Image> _loadImage() async {
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    await printReorganisedTextAndCategory();

    return frameInfo.image;
  }

 

  Future<void> printReorganisedTextAndCategory() async {
    TextClassifier _textClassifier = TextClassifier();
    List<List<TextElement>> reorganisedText = MyMLTextRecognizer.reorganiseText(recognizedText);
    
    String result = reorganisedText.map((line) {
    return line.map((element) => element.text).join(' ');
  }).join('\n');

    logger.i(result);

    String text = MyMLTextRecognizer.returnReorganisedText(reorganisedText);
    logger.i('Date: ${myRegExpClass.extractMostRecentDate(text)}');
    logger.i('Amount: ${myRegExpClass.findLargestAmount(text)}');
    /*
    _textClassifier.loadModel();
    try {
      List predictions  = await _textClassifier.predict(text);
      logger.i('Prediction: ${predictions}');
    } catch (e){
      print(e);
    }*/
    //print('Probabilities:');
    /*print('Food and Beverage: ${outputList[0]}');
    print('Groceries: ${outputList[1]}');
    print('Retail: ${outputList[2]}');*/
    
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: Text('Text Recognition Result')),
      body: SingleChildScrollView(
        child: FutureBuilder<ui.Image>(
          future: _loadImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: FittedBox(
                  child: SizedBox(
                    width: snapshot.data!.width.toDouble(),
                    height: snapshot.data!.height.toDouble(),
                    child: CustomPaint(
                      painter: TextRecognitionPainter(
                        recognizedText: recognizedText,
                        image: snapshot.data!,
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  


}
