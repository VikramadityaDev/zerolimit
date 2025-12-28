import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zerolimit/screens/home_src.dart';
import 'package:zerolimit/screens/two_factor_auth.dart';
import 'package:zerolimit/screens/viewer_src.dart';

import '../screens/otp_src.dart';
import '../screens/startup.dart';

const String _baseUrl = 'https://zerolimitbackend-production.up.railway.app/';

class LoginService {
  /// To send the OTP to the phone
  Future<void> sendOtp(String phone, BuildContext context) async {
    var url = Uri.parse('${_baseUrl}send_otp');
    var response = await http.post(
      url,
      headers: {'content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'phone_number': phone}),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpScreen(phone: phone, phoneHash: data['phone_code_hash']),
        ),
      );
    } else {
      print('Server Error: ${response.statusCode}');
    }
  }

  /// To verify the OTP
  Future<void> verifyOtp(
    String phone,
    String phoneHash,
    String otp,
    BuildContext context,
  ) async {
    var url = Uri.parse('${_baseUrl}sign_in');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone_number': phone,
        'phone_code_hash': phoneHash,
        'code': otp,
      }),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print(response.body);
      await setString(data['session_string']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (response.statusCode == 401) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TwoFactorAuth(phone: phone)),
      );
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  Future<void> checkPassword(
    String phone,
    String password,
    BuildContext context,
  ) async {
    var url = Uri.parse('${_baseUrl}confirm_2fa');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'phone_number': phone, 'password': password}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print(response.body);
      await setString(data['session_string']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) =>  HomeScreen()),
            (Route<dynamic> route) => false,
      );
    } else if (response.statusCode == 401) {
      throw Exception("Wrong 2FA password");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  Future<void> sendMessage() async {
    var token = await getString();
    var url = Uri.parse('${_baseUrl}send');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'auth': token,
      },
    );
    print(response.body);
  }

  /// To upload image and video
  Future<void> uploadFile(XFile file, BuildContext context) async {
    var token = await getString();
    var dio = Dio();

    String fileName = path.basename(file.path);

    final progressNotifier = ValueNotifier<int>(0);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      duration: const Duration(days: 1),
      content: ValueListenableBuilder<int>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Uploading $fileName"),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 4),
              Text('$value%'),
            ],
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dio.post(
        '${_baseUrl}upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != 0) {
            int progress = ((sent / total) * 100).toInt();
            progressNotifier.value = progress;
          }
        },
        options: Options(
          headers: {
            'auth': token,
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Upload successful"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Upload failed"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }
  }


  Future<List<Map<String, dynamic>>> fetchMedia() async {
    final token = await getString(); /// session_string stored locally
    final url = Uri.parse('${_baseUrl}fetch_media');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'auth': token,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> mediaList = jsonDecode(response.body);
        return mediaList.map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();
      } else {
        print("Failed to fetch media: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching media: $e");
      return [];
    }
  }

  Future<void> viewMedia(BuildContext context, int fileId, String type) async {
    final token = await getString();
    final url = '$_baseUrl/view/$fileId?token=$token';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(url: url, type: type),
      ),
    );
  }

  Future<void> downloadMedia({
    required BuildContext context,
    required int fileId,
    required String fileName,
    required String type,
    required Function(int received, int total) onProgress,
  }) async {
    final token = await getString();
    final url = '$_baseUrl/view/$fileId?token=$token';

    try {
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }
      }

      final baseDir = Directory('/storage/emulated/0/Download');
      final subFolder = {
        'photo': 'Photos',
        'video': 'Videos',
        'doc': 'Docs',
        'apk': 'APKs',
      }[type.toLowerCase()] ?? 'Others';

      final saveDir = Directory(path.join(baseDir.path, 'Zerolimit', subFolder));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final savePath = path.join(saveDir.path, fileName);
      final dio = Dio();

      int progress = 0;

      /// Controller to update progress in real time
      final progressNotifier = ValueNotifier<int>(0);

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        duration: const Duration(days: 1),
        content: ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Downloading $fileName"),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 4),
                Text('$value%'),
              ],
            );
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      final response = await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress = ((received / total) * 100).toInt();
            progressNotifier.value = progress;
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Downloaded to: $savePath"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Download failed."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }
  }


}
