
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class UserManualScreen extends StatefulWidget {
  final String pdfUrl;

  const UserManualScreen({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<UserManualScreen> createState() =>
      _UserManualScreenState();
}

class _UserManualScreenState
    extends State<UserManualScreen> {
  int retryCount = 0;

  void retryPdf() {
    setState(() {
      retryCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.pdfUrl.trim());

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
      body: uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' &&
              uri.scheme != 'https')
          ? const Center(
        child: Text('Invalid PDF URL'),
      )
          : PdfViewer.uri(
        uri,
        key: ValueKey(
          '${widget.pdfUrl}_$retryCount',
        ),
        params: PdfViewerParams(
          loadingBannerBuilder:
              (context, downloaded, total) {
            return Center(
              child: CircularProgressIndicator(
                value: total != null && total > 0
                    ? downloaded / total
                    : null,
              ),
            );
          },
          errorBannerBuilder:
              (context, error, stackTrace,
              documentRef) {
            return Center(
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
                    const Text(
                      'Unable to load user manual',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
            );
          },
        ),
      ),
    );
  }
}
