import 'package:flutter/material.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/country.dart';
import 'package:zerolimit/services/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginService = LoginService();
  final TextEditingController phoneNumberController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorText;
  bool isWaiting = false;
  Country selectedCountry = CountryPickerUtils.getCountryByIsoCode('IN');
  String get phoneNumber => phoneNumberController.text.trim();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 225, 102, 1.0),
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
                SizedBox(height: 12),
                // Text(
                //   "ZeroLimit",
                //   style: TextStyle(
                //     fontSize: 28,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                Text(
                  "Sign in with your Telegram Account",
                  style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1.0),),
                ),
                SizedBox(height: 32),

                /// Phone input container
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color.fromRGBO(0, 0, 0, 1.0), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openCountryPickerDialog,
                        child: Row(
                          children: [
                            CountryPickerUtils.getDefaultFlagImage(selectedCountry),
                            SizedBox(width: 8),
                            Text("+${selectedCountry.phoneCode}"),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Phone number',

                          ),
                          style: TextStyle(fontSize: 16),
                          onChanged: (_) => setState(() => errorText = null),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Validation Message
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
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
                    String fullPhone = '+${selectedCountry.phoneCode}$number';
                    await loginService.sendOtp(fullPhone, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(191, 107, 207, 1.0),
                    foregroundColor: Color.fromRGBO(0, 0, 0, 1.0),
                    side: BorderSide(color: Color.fromRGBO(0, 0, 0, 1.0), width: 2),
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
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCountryPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(primaryColor: Colors.blue),
        child: CountryPickerDialog(
          titlePadding: EdgeInsets.all(8.0),
          searchCursorColor: Colors.blue,
          searchInputDecoration: InputDecoration(hintText: 'Search...'),
          isSearchable: true,
          title: Text('Select your country'),
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
      SizedBox(width: 8.0),
      Text("+${country.phoneCode}"),
      SizedBox(width: 8.0),
      Expanded(child: Text(country.name)),
    ],
  );
}
