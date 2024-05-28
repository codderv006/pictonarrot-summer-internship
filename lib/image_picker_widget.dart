import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(File?) onImagePicked;

  ImagePickerWidget({required this.onImagePicked});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    PickedFile? pickedFile;

    if (kIsWeb) {
      // Use the image picker for web
      pickedFile = await _picker.getImage(source: ImageSource.gallery);
    } else {
      // Use the image picker for mobile
      pickedFile = await _picker.getImage(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      onImagePicked(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickImage(context),
      child: Text('Pick an Image'),
    );
  }
}
