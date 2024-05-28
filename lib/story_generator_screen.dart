import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'image_picker_widget.dart';
import 'package:path_provider/path_provider.dart';

class StoryGeneratorScreen extends StatefulWidget {
  @override
  _StoryGeneratorScreenState createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  String _story = 'No story generated yet.';
  File? _imageFile;
  FlutterTts _flutterTts = FlutterTts();
  AudioPlayer _audioPlayer = AudioPlayer();
  String _audioUrl = '';

  Future<void> _generateStory(File imageFile) async {
    try {
      final String imageUrl = await _uploadImage(imageFile);
      final String story = await _getStoryFromNgrok(imageUrl);

      setState(() {
        _story = story;
      });

      await _convertStoryToSpeech(story);
    } catch (e) {
      print('Error: $e');
      setState(() {
        _story = 'Error: $e';
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final String cloudName = 'dzpg27lh3';
    final String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    final mimeType = lookupMimeType(image.path);

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields['upload_preset'] = 'ml_default'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType.parse(mimeType!),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);
      final imageUrl = data['secure_url'];
      print('Uploaded image URL: $imageUrl');
      return imageUrl;
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<String> _getStoryFromNgrok(String imageUrl) async {
    final String apiUrl = 'https://3781-103-111-133-161.ngrok-free.app/generate_description/?image_url=$imageUrl';

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['description'];
    } else {
      throw Exception('Failed to get story. Status code: ${response.statusCode}');
    }
  }

  Future<void> _convertStoryToSpeech(String story) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);

    final tempDir = await getTemporaryDirectory();
    final audioFile = File('${tempDir.path}/story.mp3');
    await _flutterTts.synthesizeToFile(story, audioFile.path);

    setState(() {
      _audioUrl = audioFile.path;
    });
  }

  void _onImagePicked(File? image) {
    if (image != null) {
      setState(() {
        _imageFile = image;
        _story = 'Generating story...';
      });
      _generateStory(image);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.jpg', height: 40),
            SizedBox(width: 10),
            Text('PictoNarrot'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(_imageFile!),
                ),
              ImagePickerWidget(onImagePicked: _onImagePicked),
              SizedBox(height: 20),
              if (_audioUrl.isNotEmpty)
                Column(
                  children: [
                    Text('Listen to the story:'),
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () async {
                        await _audioPlayer.setUrl(_audioUrl);
                        _audioPlayer.play();
                      },
                    ),
                  ],
                ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: double.infinity,
                child: Text(
                  _story,
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
