import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:zerolimit/services/login_service.dart';
import 'package:zerolimit/screens/home_src.dart';
import 'package:zerolimit/screens/two_factor_auth.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.phoneHash,
  });

  final String phone;
  final String phoneHash;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final loginService = LoginService();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(244, 225, 102, 1.0),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/otp.png",
              width: w * 0.5,
              height: h * 0.11,
            ),
            SizedBox(height: h * 0.02),
            Text(
              "Enter Verification Code",
              style: TextStyle(
                fontSize: h * 0.03,
                fontWeight: FontWeight.w500,
                color: const Color.fromRGBO(0, 0, 0, 1.0),
              ),
            ),
            Text(
              "Code was sent to your Telegram Account",
              style: TextStyle(
                fontSize: h * 0.016,
                color: const Color.fromRGBO(0, 0, 0, 0.5),
              ),
            ),
            SizedBox(height: h * 0.02),

            /// OTP Input
            OtpTextField(
              numberOfFields: 5,
              fieldWidth: w * 0.15,
              disabledBorderColor: Colors.black,
              enabledBorderColor: Colors.black,
              focusedBorderColor:
              const Color.fromRGBO(191, 107, 207, 1.0),
              cursorColor:
              const Color.fromRGBO(191, 107, 207, 1.0),
              showFieldAsBox: true,
              borderRadius:
              BorderRadius.all(Radius.circular(h * 0.01)),
              onSubmit: _onOtpSubmit,
            ),

            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(
                  color:
                  const Color.fromRGBO(191, 107, 207, 1.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onOtpSubmit(String verificationCode) async {
    setState(() => isLoading = true);

    try {
      final result = await loginService.verifyOtp(
        widget.phone,
        widget.phoneHash,
        verificationCode,
      );

      if (!mounted) return;

      if (result == 'success') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      } else if (result == '2fa') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TwoFactorAuth(phone: widget.phone),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or expired OTP")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}