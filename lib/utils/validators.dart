import 'dart:convert';

import 'package:flutter/material.dart';

import '../repository/repository.dart';
import '../services/http_service.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Time complexity: O(n)
  bool hasDuplicates(List<int> list) {
    Set<int> seen = {};
    for (int num in list) {
      if (seen.contains(num)) return true;
      seen.add(num);
    }
    return false;
  }

  Future<bool> verifyPassword(BuildContext context) async {
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
                    if (jsonData['code'] == 200) {
                      if (ctx.mounted) Navigator.pop(ctx, true);
                      return;
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx, false);
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx, false);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result != true) {
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

    return result == true;
  }
}