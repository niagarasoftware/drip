import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../site_config.dart';

class PasswordProtectedSiteConfig extends StatefulWidget {
  final int userId;
  final int customerId;
  final String customerName;
  final List<MasterControllerModel> allMaster;
  final int groupId;
  final String groupName;

  const PasswordProtectedSiteConfig({
    Key? key,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.allMaster,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<PasswordProtectedSiteConfig> createState() =>
      _PasswordProtectedSiteConfigState();
}

class _PasswordProtectedSiteConfigState
    extends State<PasswordProtectedSiteConfig> {
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPassword());
  }

  Future<void> _askPassword() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final userPsw = controller.text;

                try {
                  final Repository repository = Repository(HttpService());
                  var getUserDetails = await repository.checkpassword({
                    "passkey": userPsw,
                  });

                  if (getUserDetails.statusCode == 200) {
                    var jsonData = jsonDecode(getUserDetails.body);
                    print("jsonData $jsonData");

                    if (jsonData['code'] == 200) {
                      // print("getUserDetails.body: ${getUserDetails.body}");
                      if (ctx.mounted) Navigator.pop(ctx, true); // ✅ close dialog safely
                    } else {
                      if (ctx.mounted) Navigator.pop(ctx, false); // wrong password
                    }
                  }
                } catch (e, stackTrace) {
                  print('Error getData => ${e.toString()}');
                  print('Trace getData => $stackTrace');
                  if (ctx.mounted) Navigator.pop(ctx, false);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() => _authorized = true);
    } else {
      // Wrong password → show error
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Incorrect Password!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authorized) {
      return SiteConfig(
        userId: widget.userId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        groupId: widget.groupId,
        groupName: widget.groupName,
      );
    }
    return const SizedBox.shrink();
  }
}