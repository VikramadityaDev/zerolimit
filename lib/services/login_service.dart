import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zerolimit/screens/two_factor_auth.dart';

import '../screens/bottom_bar.dart';
import '../screens/otp_src.dart';
import '../screens/startup.dart';

const String _baseUrl = 'http://192.168.1.8:5000/';

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
        MaterialPageRoute(builder: (context) => const BottomBar()),
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BottomBar()),
      );
    } else if (response.statusCode == 401) {
      print(response.body);
      Navigator.pop(context);
    } else {
      print('Error: ${response.statusCode}');
      Navigator.pop(context);
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
}
