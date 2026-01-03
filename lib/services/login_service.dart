import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/viewer_src.dart';

const String _baseUrl = 'http://192.168.1.9:5000/';

/// ======================
/// Session helpers
/// ======================
Future<void> setString(String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('string', value);
}

Future<String> getString() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('string') ?? '';
}

/// ======================
/// Login Service
/// ======================
class LoginService {
  /// ----------------------
  /// AUTH
  /// ----------------------

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final url = Uri.parse('${_baseUrl}send_otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'phone_number': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('OTP send failed (${response.statusCode})');
  }

  /// Verify OTP
  /// returns: success | 2fa
  Future<String> verifyOtp(
      String phone,
      String phoneHash,
      String otp,
      ) async {
    final url = Uri.parse('${_baseUrl}sign_in');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone_number': phone,
        'phone_code_hash': phoneHash,
        'code': otp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setString(data['session_string']);
      return 'success';
    } else if (response.statusCode == 401) {
      return '2fa';
    }
    throw Exception('OTP verification failed');
  }

  /// Verify 2FA password
  Future<void> checkPassword(
      String phone,
      String password,
      ) async {
    final url = Uri.parse('${_baseUrl}confirm_2fa');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone_number': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setString(data['session_string']);
      return;
    }
    throw Exception('Wrong 2FA password');
  }

  /// ----------------------
  /// TELEGRAM ACTIONS
  /// ----------------------

  /// Send test message
  Future<void> sendMessage() async {
    final token = await getString();
    final url = Uri.parse('${_baseUrl}send');

    final response = await http.get(
      url,
      headers: {'auth': token},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  /// Upload file to Telegram Saved Messages
  Future<Map<String, dynamic>> uploadFile(
      XFile file, {
        required void Function(double progress) onProgress,
      }) async {
    final token = await getString();
    final url = Uri.parse('${_baseUrl}upload');

    final request = http.MultipartRequest('POST', url);
    request.headers['auth'] = token;

    final fileLength = await file.length();
    int bytesSent = 0;

    final stream = http.ByteStream(
      file.openRead().transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            onProgress(bytesSent / fileLength);
            sink.add(data);
          },
        ),
      ),
    );

    request.files.add(
      http.MultipartFile(
        'file',
        stream,
        fileLength,
        filename: path.basename(file.path),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    onProgress(1.0);

    if (response.statusCode != 200) {
      throw Exception('Upload failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }



  /// Fetch media from Telegram Saved Messages
  Future<List<Map<String, dynamic>>> fetchMedia({
    int offsetId = 0,
    int limit = 20,
  }) async {
    final token = await getString();

    final url = Uri.parse(
      '${_baseUrl}fetch_media?offset_id=$offsetId&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'auth': token,
      },
    );
    if (response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('Failed to fetch media');
  }


  /// Download media file bytes (for preview or saving)
  Future<List<int>> downloadMedia(int fileId) async {
    final token = await getString();
    final url = Uri.parse('${_baseUrl}fetch_media/$fileId');

    final response = await http.get(
      url,
      headers: {'auth': token},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    throw Exception('Failed to download media');
  }

  Future<void> viewMedia(BuildContext context, int fileId,String type,) async {
    final token = await getString();

    Navigator.push(context, MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          url: '$_baseUrl/view/$fileId',
          type: type,
          headers: {
            'auth': token,
          },
        ),
      ),
    );
  }
}
