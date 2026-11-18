import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/network_utils.dart';

class NetworkConnectionBanner extends StatelessWidget {
  const NetworkConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NetworkUtils.connectionStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.data!) {
          return Container(
            color: Colors.red.shade400,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 8, right: 8, top: 3, bottom: 3),
            child: const Text(
              'No Internet Connection',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}