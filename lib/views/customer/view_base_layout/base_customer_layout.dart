import 'package:flutter/material.dart';

class BaseCustomerLayout extends StatelessWidget {
  final Widget body;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? banners;

  const BaseCustomerLayout({
    super.key,
    required this.body,
    this.scaffoldKey,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.banners,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      endDrawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          if (banners != null) ...banners!,
          Expanded(child: body),
        ],
      ),
    );
  }
}