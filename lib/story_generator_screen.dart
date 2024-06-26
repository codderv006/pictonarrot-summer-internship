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
import 'package:audio_session/audio_session.dart';

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
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  int _currentWordIndex = -1;
  List<String> _words = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _audioDuration = duration ?? Duration.zero;
      });
    });
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
        _updateCurrentWordIndex();
      });
    });
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(0.8); // Slow down the voice
    await _flutterTts.setVoice({"name": "en-us-x-sfg#male_1-local", "locale": "en-US"}); // Change voice
  }

  Future<void> _generateStory(File imageFile) async {
    setState(() {
      _isLoading = true;
      _story = 'Generating the story...';
    });

    try {
      final String imageUrl = await _uploadImage(imageFile);
      final String story = await _getStoryFromNgrok(imageUrl);

      setState(() {
        _story = story;
        _words = _splitIntoWords(story);
        _isLoading = false;
      });

      await _convertStoryToSpeech(story);
    } catch (e) {
      print('Error: $e');
      setState(() {
        _story = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _splitIntoWords(String story) {
    return story.split(RegExp(r'(\s+|\b)')).where((word) => word.trim().isNotEmpty).toList();
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
    final String apiUrl = 'https://072e-103-111-133-161.ngrok-free.app/generate_description/?image_url=$imageUrl';

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['description'];
    } else {
      throw Exception('Failed to get story. Status code: ${response.statusCode}');
    }
  }

  Future<void> _convertStoryToSpeech(String story) async {
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
      });
    }
  }

  void _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setUrl(_audioUrl);
      await _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _updateCurrentWordIndex() {
    if (_audioDuration.inMilliseconds > 0) {
      final totalDuration = _audioDuration.inMilliseconds;
      final currentPosition = _currentPosition.inMilliseconds;
      final wordIndex = (currentPosition / totalDuration * _words.length).floor();
      setState(() {
        _currentWordIndex = wordIndex;
      });
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
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Image.file(_imageFile!),
                    ),
                    ElevatedButton(
                      onPressed: () => _generateStory(_imageFile!),
                      child: Text('Generate Story'),
                    ),
                  ],
                ),
              ImagePickerWidget(onImagePicked: _onImagePicked),
              SizedBox(height: 20),
              if (_audioUrl.isNotEmpty)
                Column(
                  children: [
                    Text('Listen to the story:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: _playPauseAudio,
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _audioDuration.inMilliseconds.toDouble()),
                            max: _audioDuration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              final newPosition = Duration(milliseconds: value.toInt());
                              _audioPlayer.seek(newPosition);
                            },
                          ),

                        ),
                      ],
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
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: _words.asMap().entries.map((entry) {
                      final index = entry.key;
                      final word = entry.value;
                      final isCurrent = index == _currentWordIndex;
                      return TextSpan(
                        text: '$word ',
                        style: TextStyle(
                          color: isCurrent ? Colors.blue : Colors.black,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
