import 'package:flutter/material.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({
    super.key,
    required this.pdfUrl,
  });

  final String pdfUrl;

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  PDFDocument? document;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final pdf = await PDFDocument.fromURL(widget.pdfUrl);

      if (!mounted) return;

      setState(() {
        document = pdf;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load PDF: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Manual'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : document == null
          ? const Center(
        child: Text('Unable to load user manual'),
      )
          : PDFViewer(
        document: document!,
        lazyLoad: false,
        zoomSteps: 1,
      ),
    );
  }
}
