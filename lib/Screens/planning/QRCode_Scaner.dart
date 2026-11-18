/*
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class QRCodeScan extends StatefulWidget {
  const QRCodeScan({Key? key}) : super(key: key);

  @override
  State<QRCodeScan> createState() => _QRCodeScanState();
}

class _QRCodeScanState extends State<QRCodeScan> {
  String scannedData = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Scanner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (_) => const QRViewExample(),
                ))
                    .then((value) {
                  if (value != null) {
                    setState(() {
                      scannedData = value;
                    });
                  }
                });
              },
              child: const Text('Start QR Scan'),
            ),
            const SizedBox(height: 16),
            if (scannedData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  scannedData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final MobileScannerController controller = MobileScannerController();
  bool hasScanned = false;
  double _zoom = 0.0;

  Future<void> _playBeep() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (hasScanned) return;
    hasScanned = true;

    final Barcode barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null) {
      await _playBeep();
      controller.stop();
      Navigator.of(context).pop(code);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    const boxSize = 250.0;
                    final left = (width - boxSize) / 2;
                    final top = (height - boxSize) / 2;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            // color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        Positioned(
                          left: left,
                          top: top,
                          child: Container(
                            width: boxSize,
                            height: boxSize,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.red, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: HolePainter(
                                rect: Rect.fromLTWH(left, top, boxSize, boxSize),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text('Use the buttons below for control:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () => controller.toggleTorch(),
                      child: const Text('Toggle Flash'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => controller.switchCamera(),
                      child: const Text('Switch Camera'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Zoom'),
                Slider(
                  value: _zoom,
                  onChanged: (value) {
                    setState(() {
                      _zoom = value;
                    });
                    controller.setZoomScale(value);
                  },
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: _zoom.toStringAsFixed(1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => controller.stop(),
                      child: const Text('Pause'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () => controller.start(),
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  final Rect rect;

  HolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRect(rect);
    final path = Path.combine(PathOperation.difference, outer, hole);

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..blendMode = BlendMode.srcOver;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HolePainter oldDelegate) => oldDelegate.rect != rect;
}
*/
