import 'package:flutter/material.dart';
import 'story_generator_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Story Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StoryGeneratorScreen(),
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}
