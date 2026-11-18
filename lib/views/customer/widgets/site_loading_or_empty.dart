import 'package:flutter/material.dart';

class SiteLoadingOrEmpty extends StatelessWidget {
  final bool isLoading;
  const SiteLoadingOrEmpty({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const Scaffold(
      body: Center(child: Text("No site data available")),
    );
  }
}