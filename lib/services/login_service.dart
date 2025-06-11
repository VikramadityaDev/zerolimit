import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screens/otp_src.dart';

const String _baseUrl = 'http://192.168.1.8:5000/';

class LoginService {
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
        MaterialPageRoute(builder: (context) => OtpScreen()),
      );
    } else {
      print('Server Error: ${response.statusCode}');
    }
  }
}
