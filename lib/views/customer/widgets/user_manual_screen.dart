import 'package:flutter/material.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';

class UserManualScreen extends StatefulWidget {
  final String pdfUrl;

  const UserManualScreen({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  PDFDocument? document;
  bool isLoading = true;
  String? errorMessage;
  int retryCount = 0;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    final uri = Uri.tryParse(widget.pdfUrl.trim());

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid PDF URL';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      document = null;
    });

    try {
      final pdf = await PDFDocument.fromURL(
        widget.pdfUrl.trim(),
      );

      if (!mounted) return;

      setState(() {
        document = pdf;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load user manual.\n$e';
      });
    }
  }

  void retryPdf() {
    retryCount++;
    loadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Manual'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload PDF',
            onPressed: retryPdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: retryPdf,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : document != null
          ? PDFViewer(
        key: ValueKey(
          '${widget.pdfUrl}_$retryCount',
        ),
        document: document!,
      )
          : const Center(
        child: Text('Unable to load user manual'),
      ),
    );
  }
}
