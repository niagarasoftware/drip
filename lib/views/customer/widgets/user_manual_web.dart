
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class UserManualWeb extends StatefulWidget {
  final String pdfUrl;

  const UserManualWeb({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<UserManualWeb> createState() => _UserManualWebState();
}

class _UserManualWebState extends State<UserManualWeb> {
  late final String viewType;

  @override
  void initState() {
    super.initState();

    viewType = 'pdf-viewer-${identityHashCode(this)}';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
          (int id) {
        final iframe = web.HTMLIFrameElement()
          ..src = widget.pdfUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open PDF in browser',
            onPressed: () {
              web.window.open(widget.pdfUrl, '_blank');
            },
          ),
        ],
      ),
      body: HtmlElementView(viewType: viewType),
    );
  }
}

typedef UserManualWidget = UserManualWeb;
