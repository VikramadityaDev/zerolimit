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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  // Perform asynchronous operation
                  await loginService.checkPassword(
                      widget.phone, password, context);
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
                child: const Text("Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
