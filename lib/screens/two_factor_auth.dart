import 'package:flutter/material.dart';

import '../services/login_service.dart';

class TwoFactorAuth extends StatefulWidget {
  const TwoFactorAuth({super.key, required this.phone});

  final String phone;

  @override
  State<TwoFactorAuth> createState() => _TwoFactorAuthState();
}

class _TwoFactorAuthState extends State<TwoFactorAuth> {
  final loginService = LoginService();
  String password = '';
  bool isWaiting = false;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(244, 225, 102, 1.0),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(
              //   height: height * 0.1,
              // ),
              Image.asset(
                "assets/images/2FA.png",
                width: width * 0.5,
                height: height * 0.11,
              ),
              SizedBox(height: height * 0.01),
              const Text(
                "Enter your cloud password",
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1.0),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: width * 0.9,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      password = value;
                      errorText = null;
                    });
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromRGBO(0, 0, 0, 1.0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: 'Password',
                  ),
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isWaiting
                    ? null
                    : () async {
                  if (password.isEmpty) {
                    setState(() {
                      errorText = "Password cannot be empty";
                    });
                    return;
                  }

                  setState(() {
                    isWaiting = true;
                    errorText = null;
                  });

                  try {
                    await loginService.checkPassword(
                      widget.phone,
                      password,
                      context,
                    );
                  } catch (e) {
                    setState(() {
                      errorText = "Incorrect password";
                      isWaiting = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(191, 107, 207, 1.0),
                  foregroundColor: Color.fromRGBO(0, 0, 0, 1.0),
                  side: BorderSide(
                    color: Color.fromRGBO(0, 0, 0, 1.0),
                    width: 2,
                  ),
                  minimumSize: Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isWaiting ? "Please wait.." : "Next",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}