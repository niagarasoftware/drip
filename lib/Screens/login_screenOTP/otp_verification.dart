import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/shared_preferences_helper.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


// ignore: must_be_immutable
class OtpVerifyScreen extends StatefulWidget {
  String contact;

  OtpVerifyScreen({super.key, required this.contact});

  @override
  _OtpVerifyScreenState createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  late String phoneNo;
  late String smsOTP;
  late String verificationId;
  String errorMessage = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
  String deveicetoken = '';

  //this is method is used to initialize data
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      // widget.contact = '${ModalRoute.of(context)?.settings.arguments as String}';
      AppLog.log(widget.contact);
      generateOtp(widget.contact);

    });
  }

  //dispose controllers
  @override
  void dispose() {
    super.dispose();
  }

  //build method for UI
  @override
  Widget build(BuildContext context) {
    //Getting screen height width
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        Navigator.pushReplacementNamed(context, '/loginOTP');
      },
      child: Scaffold(
         backgroundColor: Colors.teal.shade50,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   SizedBox(
                    height: screenHeight * 0.05,
                  ),
                  Image.asset(
                    'assets/Images/otp.png',
                    height: screenHeight * 0.3,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  const Text(
                    'Verification',
                    style: TextStyle(fontSize: 28, color: Colors.black),
                  ),
                  SizedBox(
                    height: screenHeight * 0.02,
                  ),
                  Text(
                    ' Enter the 6-digit OTP that was sent to ${widget.contact}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    'If you didn\'t receive the OTP, you can',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: (){
                      generateOtp(widget.contact);
                    },
                     child: const Text(
                      'Resend OTP',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.04,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? screenWidth * 0.2 : 16),
                    padding: const EdgeInsets.all(16.0),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.025),
                          child: OtpPinField(
                            key: _otpPinFieldKey,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            fieldWidth: 30,
                            onSubmit: (text) {
                              smsOTP = text;
                            },
                            onChange: (text) {},
                          ),
                        ),
                        SizedBox(
                          height: screenHeight * 0.04,
                        ),
                        GestureDetector(
                          onTap: (){
                            getDeviceToken();
                            verifyOtp();
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            height: 45,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 28, 123, 137),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Verify',
                              style: TextStyle(color: Colors.white, fontSize: 16.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

   Future<void> generateOtp(String contact) async {
    AppLog.log("generateOtp called");
    void smsOTPSent(String verId, int? forceResendingToken) {
      verificationId = verId;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: contact,
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        codeSent: smsOTPSent,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (AuthCredential phoneAuthCredential) {},
        verificationFailed: (error) {
          AppLog.log(error);
          _showSnackBar(error.message ?? 'verificationFailed',Colors.red);
        },
      );
    } catch (e,stackTrace) {
      AppLog.log('error generateOtp');
      AppLog.log(e.toString());
      _showSnackBar(e.toString(),Colors.red);
      AppLog.log('error $e');
      AppLog.log("stackTrace $stackTrace");
      handleError(e as PlatformException);
    }
  }

  Future<void> getDeviceToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.getToken().then((String? token) async{
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceToken', token ?? '' );
      deveicetoken = token ?? '';
    });
    }


   Future<void> verifyOtp() async {
    if (smsOTP.isEmpty || smsOTP == '') {
      showAlertDialog(context, 'please enter 6 digit otp');
      return;
    }
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );
      final UserCredential user = await _auth.signInWithCredential(credential);
      final User? currentUser = _auth.currentUser;
      assert(user.user?.uid == currentUser?.uid);
      await checkNumber(widget.contact);
    } on PlatformException catch(e){
      handleError(e);
      AppLog.log(e.toString());
      _showSnackBar(e.message!,Colors.red);
    }
    catch (e, stackTrace) {
      _showSnackBar(e.toString(),Colors.red);
      AppLog.log('error $e');
      AppLog.log("stackTrace $stackTrace");
    }
  }

  Future<bool> checkNumber(String countryCode) async {
    if (deveicetoken.isEmpty) {
      await getDeviceToken();
    }

    final parts = countryCode.trim().split(' ');
    if (parts.length < 2) {
      _showSnackBar("Invalid phone number format", Colors.red);
      return false;
    }

    final code = parts[0].replaceFirst('+', '');
    final number = parts[1];

    try {
      final body = {
        'countryCode': code,
        'mobileNumber': number,
        'deviceToken': deveicetoken,
        'isMobile': kIsWeb ? false : true,
      };
      final repository = Repository(HttpService());
      final response = await repository.checkMobileNumber(body);

       AppLog.log("response: ${response.body}");
      if (response.statusCode != 200) {
        _showSnackBar("Server error: ${response.statusCode}", Colors.red);
        return false;
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 200) {
        _showSnackBar(data['message'], Colors.red);
        return false;
      }

      final userData = data['data']['user'];

      await PreferenceHelper.saveUserDetails(
        token: userData['accessToken'],
        userId: userData['userId'],
        userName: userData['userName'],
        role: userData['userType'],
        countryCode: code,
        mobileNumber: number,
        email: userData['email'],
        configPermission: userData['permissionDenied'] ?? false,
        password: '',
      );

      // 🔹 Example: Navigate based on role
      Future.delayed(Duration.zero, () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (Route<dynamic> route) => false,
        );
        return true;
      });
      return true;
    } catch (error, stackTrace) {
      AppLog.log("Error on checkNumber $error");
      AppLog.log("StackTrace on checkNumber $stackTrace");
      _showSnackBar("Something went wrong", Colors.red);
      return false;
    }
  }


  //Method for handle the errors
  void handleError(PlatformException error) {
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(FocusNode());
        setState(() {
          errorMessage = 'Invalid Code';
        });
        showAlertDialog(context, 'Invalid Code');
        break;
      default:
        showAlertDialog(context, error.message ?? 'Warning');
        break;
    }
  }

  //Basic alert dialogue for alert errors and confirmations
  void showAlertDialog(BuildContext context, String message) {
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

  void _showSnackBar(String message,Color color) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color ,
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}