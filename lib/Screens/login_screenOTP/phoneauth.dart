import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  String? _verificationId;

  Future<void> _verifyPhoneNumber() async {
    final phoneNumber = _phoneController.text;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        AppLog.log('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  Future<void> _signInWithPhoneNumber() async {
    final smsCode = _smsController.text;

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    await _auth.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Auth')),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          ElevatedButton(
            onPressed: _verifyPhoneNumber,
            child: const Text('Verify Phone Number'),
          ),
          TextField(
            controller: _smsController,
            decoration: const InputDecoration(labelText: 'SMS Code'),
          ),
          ElevatedButton(
            onPressed: _signInWithPhoneNumber,
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
