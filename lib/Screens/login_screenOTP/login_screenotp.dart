import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:oro_drip_irrigation/Screens/login_screenOTP/widget/custom_button.dart';
 import 'package:shared_preferences/shared_preferences.dart';

import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../views/common/login/login_screen.dart';
import 'otp_verification.dart';

class LoginScreenOTP extends StatefulWidget {
  const LoginScreenOTP({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenOTP> {
  bool isManualDialCodeEntry = false;
  final TextEditingController _contactEditingController = TextEditingController();
  String? dialCodeError;
  int _clickCount = 0;
  String isoCode = 'IN';
  // late List<Map<String, String>> countryCodes = [];

  String? selectedCountryDialCode = "+91";
  String deveicetoken = '';

  @override
  void initState() {
    super.initState();
   }

  Future<void> clickOnLogin(BuildContext context) async {
    await getDeviceToken();

    if (_contactEditingController.text.isEmpty) {
      showErrorDialog(context, 'Register number can\'t be empty.');
    } else {
      String checkval = await checkNumber(selectedCountryDialCode!, _contactEditingController.text);
      if (checkval == 'true') {

        final responseMessage = await Navigator.push(context, MaterialPageRoute(builder: (context) => OtpVerifyScreen(contact: "$selectedCountryDialCode ${_contactEditingController.text}",)));
        if (responseMessage != null) {
          showErrorDialog(context, responseMessage as String);
        }
      } else {
        _contactEditingController.text = '';
        showErrorDialog(context,
            'This is Not Register Number \n Enter Register Correct Number');
      }
    }
  }

  Future<void> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('deviceToken') ?? '';

    setState(() {
      deveicetoken = token;
    });
  }

  Future<String> checkNumber(String countryCode, String mobileNumber) async {

    // verifyOtp();
    if(deveicetoken.isEmpty || deveicetoken == '')
    {
      await getDeviceToken();
    }
    Map<String, Object> body = {
      'countryCode': countryCode.replaceFirst('+', ''),
      'mobileNumber': mobileNumber,
      // 'macAddress': '123456',
      'deviceToken': deveicetoken,
      'isMobile': true
    };
     final repository = Repository(HttpService());
    final response = await repository.checkMobileNumber(body);

     if (response.statusCode == 200) {
       if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("data$data");
         if (data["code"] == 200) {


          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
                  (Route<dynamic> route) => false,
            );
          }
          return 'true';
        } else {
          // _showSnackBar(
          //     data["message"]);
          return 'false';
        }
      } else {
        return 'false';
      }
    } else {
      return 'false';
    }
  }

  //Alert dialogue to show error and response
  void showErrorDialog(BuildContext context, String message) {
    // set up the AlertDialog
    final CupertinoAlertDialog alert = CupertinoAlertDialog(
      title: const Text('Warning'),
      content: Text('\n$message'),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // To track the number of clicks

  void _handleTap() {
    setState(() {
      _clickCount++;
      // if (_clickCount >= 7) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        // Reset click count after navigation
        _clickCount = 0;
      // }
    });
  }


  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Exit"),
        content: const Text("Do you want to exit?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => exit(0),
            // onPressed: () => Navigator.of(context).pop(true),// Return true to pop the route
            child: const Text(
              "Yes",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(false), // Return false to stay on the route
            child: const Text(
              "No",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  //build method for UI Representation
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: screenHeight * 0.05,
                  ),
                  GestureDetector(
                    onTap: _handleTap,
                    child: Image.asset(
                      'assets/Images/otpmobile.png',
                      height: screenHeight * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  const Text(
                    'Login with OTP',
                    style: TextStyle(fontSize: 28, color: Colors.black),
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  const SizedBox(
                    height: 40,
                    width: 50,
                  ),
                  const Text(
                    'Enter your Register mobile number to get an OTP and complete the verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.06,
                  ),
                  Container(
                    width: 465,
                    padding: const EdgeInsets.fromLTRB(5, 35, 10, 0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        // ignore: prefer_const_literals_to_create_immutables
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 1.0), //(x,y)
                            blurRadius: 6.0,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(16.0)),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 450,
                          height: 77,
                          child:    Column(
                            children: [
                              IntlPhoneField(
                                controller: _contactEditingController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: () {
                                      _contactEditingController.clear();
                                    },
                                  ),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                ),
                                initialCountryCode: 'IN',
                                onChanged: (phone) {
                                  selectedCountryDialCode = phone.countryCode;
                                },
                              ),
                            ],
                          ),

                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomButton(clickOnLogin),
                         const Text(
                          'or',
                         ),
                        TextButton(
                          onPressed: _handleTap,
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: Colors.grey.shade400,
                            // backgroundColor:const Color.fromARGB(255, 28, 123, 137),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Login with Password',
                            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 28, 123, 137)),
                          ),
                        )

                      ],
                    ),
                  ),

                ]),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
