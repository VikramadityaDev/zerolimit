import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerolimit/screens/bottom_bar.dart';
import 'package:zerolimit/screens/login_scr.dart';

Future<void> setString(String value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('string', value);
}

Future<String> getString() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString('string') ?? '';
  return value;
}

class StartUp extends StatefulWidget {
  const StartUp({super.key});

  @override
  State<StartUp> createState() => _StartUpState();
}

class _StartUpState extends State<StartUp> {
  bool isLoading = true;
  String loginToken = '';

  @override
  void initState() {
    super.initState();
    /// Call the asynchronous method in initState
    getString().then((value) {
      setState(() {
        loginToken = value;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: loginToken == '' ? LoginScreen() : BottomBar()
    );
  }
}
