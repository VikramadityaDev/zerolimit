import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:zerolimit/services/login_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key, required this.phone, required this.phoneHash,
  });
  final String phone;
  final String phoneHash;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final loginService = LoginService();
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(244, 225, 102, 1.0),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // SizedBox(
          //   height: h * 0.2,
          // ),
          Image.asset(
            "assets/images/otp.png",
            width: w * 0.5,
            height: h * 0.11,
          ),
          SizedBox(
            height: h * 0.02,
          ),
          Text(
            "Enter Verification Code",
            style: TextStyle(
              fontSize: h * 0.03,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 0, 0, 1.0),
            ),
          ),
          // SizedBox(
          //   height: h * 0.01,
          // ),
          Text(
            "Code was sent to your Telegram Account",
            style: TextStyle(
              fontSize: h * 0.016,
              color: Color.fromRGBO(0, 0, 0, 0.5),
            ),
          ),
          SizedBox(
            height: h * 0.02,
          ),
          OtpTextField(
            numberOfFields: 5,
            fieldWidth: w * 0.15,
            disabledBorderColor: Colors.black,
            enabledBorderColor: Colors.black,
            focusedBorderColor: Color.fromRGBO(191, 107, 207, 1.0),
            cursorColor: Color.fromRGBO(191, 107, 207, 1.0),
            showFieldAsBox: true,
            borderRadius: BorderRadius.all(Radius.circular(h * 0.01)),
            onSubmit: (String verificationCode) async {
              // print(widget.phone);
              // print(widget.phoneHash);
              print(verificationCode);
              await loginService.verifyOtp(
                  widget.phone, widget.phoneHash, verificationCode, context);
            }, // end onSubmit
          ),
        ]),
      ),
    );
  }
}
