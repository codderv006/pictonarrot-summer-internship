import 'dart:convert';

import 'package:flutter/material.dart';

class McqScreen extends StatefulWidget {
  final Map<String, dynamic> questions;

  const McqScreen({Key? key, required this.questions}) : super(key: key);

  @override
  _McqScreenState createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _selectedAnswers;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = {};
  }

  void _answerSelected(int questionIndex, int answerIndex) {
    setState(() {
      _selectedAnswers![questionIndex.toString()] = answerIndex;
    });
  }

  void _submitAnswers() {
    int correctAnswers = 0;
    _selectedAnswers!.forEach((key, value) {
      final int questionIndex = int.parse(key);
      if (widget.questions.containsKey('question${questionIndex + 1}')) {
        final List<dynamic> options =
        widget.questions['question${questionIndex + 1}']['options'];
        if (value == 0 && options[value] == options.first) {
          correctAnswers++;
        }
      }
    });

    setState(() {
      _score = correctAnswers;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thank you for providing your responses!'),
          content: Text(
              'Your score: $_score out of ${widget.questions.length}'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Your Knowledge'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question =
                      widget.questions['question${index + 1}'] ?? {};
                  final description = question['description'] ?? '';
                  final options = List<String>.from(question['options'] ?? []);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${index + 1}:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Text(description),
                          SizedBox(height: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(options.length, (optIndex) {
                              return RadioListTile<int>(
                                title: Text(options[optIndex]),
                                value: optIndex,
                                groupValue: _selectedAnswers![index.toString()],
                                onChanged: (value) => _answerSelected(index, value!),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _selectedAnswers!.length == widget.questions.length
                  ? _submitAnswers
                  : null,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
