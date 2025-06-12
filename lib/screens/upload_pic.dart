// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/login_service.dart';

class UploadPic extends StatefulWidget {
  const UploadPic({super.key});

  @override
  State<UploadPic> createState() => _UploadPicState();
}

class _UploadPicState extends State<UploadPic> {
  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final loginService = LoginService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Picture'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF9B4BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0))),
            onPressed: ()async {
              pickImage();
              await loginService.sendMessage();
            },
            child: const Text('Upload Picture')),
      ),
    );
  }
}
