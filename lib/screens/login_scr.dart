import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/country.dart';
import 'package:zerolimit/services/login_service.dart';
import 'package:zerolimit/screens/otp_src.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final loginService = LoginService();
  final TextEditingController phoneNumberController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? errorText;
  bool isWaiting = false;

  Country selectedCountry =
  CountryPickerUtils.getCountryByIsoCode('IN');

  String get phoneNumber => phoneNumberController.text.trim();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 225, 102, 1.0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  "assets/images/logo1.png",
                  height: size.height * 0.22,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sign in with your Telegram Account",
                  style: TextStyle(
                    color: Color.fromRGBO(0, 0, 0, 1.0),
                  ),
                ),
                const SizedBox(height: 32),

                /// Phone input
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(0, 0, 0, 1.0),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openCountryPickerDialog,
                        child: Row(
                          children: [
                            CountryPickerUtils
                                .getDefaultFlagImage(selectedCountry),
                            const SizedBox(width: 8),
                            Text("+${selectedCountry.phoneCode}"),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Phone number',
                          ),
                          style: const TextStyle(fontSize: 16),
                          onChanged: (_) =>
                              setState(() => errorText = null),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Error text
                if (errorText != null)
                  Padding(
                    padding:
                    const EdgeInsets.only(top: 6, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isWaiting ? null : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color.fromRGBO(191, 107, 207, 1.0),
                    foregroundColor:
                    const Color.fromRGBO(0, 0, 0, 1.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(0, 0, 0, 1.0),
                      width: 2,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isWaiting ? "Please wait.." : "Next",
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNextPressed() async {
    final number = phoneNumber;

    if (number.isEmpty) {
      setState(() {
        errorText = "Please enter your phone number";
        isWaiting = false;
      });
      return;
    }

    if (!RegExp(r'^[0-9]{6,15}$').hasMatch(number)) {
      setState(() {
        errorText = "Invalid phone number";
        isWaiting = false;
      });
      return;
    }

    setState(() {
      errorText = null;
      isWaiting = true;
    });

    final fullPhone =
        '+${selectedCountry.phoneCode}$number';

    try {
      final result = await loginService.sendOtp(fullPhone);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: fullPhone,
            phoneHash: result['phone_code_hash'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorText = "Failed to send OTP";
      });
    } finally {
      setState(() => isWaiting = false);
    }
  }

  void _openCountryPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Colors.blue),
        child: CountryPickerDialog(
          titlePadding: const EdgeInsets.all(8.0),
          searchCursorColor: Colors.blue,
          searchInputDecoration:
          const InputDecoration(hintText: 'Search...'),
          isSearchable: true,
          title: const Text('Select your country'),
          onValuePicked: (Country country) {
            setState(() => selectedCountry = country);
          },
          itemBuilder: _buildCountryItem,
        ),
      ),
    );
  }

  Widget _buildCountryItem(Country country) => Row(
    children: [
      CountryPickerUtils.getDefaultFlagImage(country),
      const SizedBox(width: 8.0),
      Text("+${country.phoneCode}"),
      const SizedBox(width: 8.0),
      Expanded(child: Text(country.name)),
    ],
  );
}
