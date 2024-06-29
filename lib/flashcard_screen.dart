import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashcardScreen extends StatefulWidget {
  final Map<String, dynamic> grammarElements;

  FlashcardScreen({required this.grammarElements});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  FlutterTts _flutterTts = FlutterTts();
  int _currentIndex = 0;
  List<String> _elements = [];
  String _currentCategory = '';

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  void _loadElements() {
    setState(() {
      var categoryElements = widget.grammarElements[_currentCategory];
      if (categoryElements is String) {
        _elements = categoryElements.split(', ').map((e) => e.trim()).toList();
      } else if (categoryElements is List) {
        _elements = categoryElements.map((e) => e.toString().trim()).toList();
      }
      _currentIndex = 0;
    });
  }

  void _speak(String text) {
    _flutterTts.speak(text);
  }

  void _nextElement() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _elements.length;
    });
  }

  void _previousElement() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _elements.length) % _elements.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
      ),
      body: _currentCategory.isEmpty ? _buildCategorySelection() : _buildFlashcardView(),
    );
  }

  Widget _buildCategorySelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCategoryButton('nouns'),
          SizedBox(height: 10),
          _buildCategoryButton('adjectives'),
          SizedBox(height: 10),
          _buildCategoryButton('prepositions'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentCategory = category;
            _loadElements();
          });
        },
        child: Text(category.capitalize()),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildFlashcardView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFlashcard(_elements[_currentIndex]),
        SizedBox(height: 20),
        _buildControls(),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _currentCategory = '';
            });
          },
          child: Text('Back'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard(String text) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(_currentIndex),
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(20),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _previousElement,
        ),
        IconButton(
          icon: Icon(Icons.volume_up),
          onPressed: () => _speak(_elements[_currentIndex]),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: _nextElement,
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + this.substring(1);
  }
}
