import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

// Placeholder for LoopingGif (replace with actual implementation)
class LoopingGif extends StatelessWidget {
  final String assetPath;
  final double height;
  final double width;

  const LoopingGif({
    Key? key,
    required this.assetPath,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      repeat: ImageRepeat.repeat, // Loops the GIF
    );
  }
}

class MyAppgif extends StatefulWidget {
  const MyAppgif({Key? key}) : super(key: key);

  @override
  _MyAppgifState createState() => _MyAppgifState();
}

class _MyAppgifState extends State<MyAppgif> with TickerProviderStateMixin {
  late GifController controller;

  @override
  void initState() {
    super.initState();
    controller = GifController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Looping GIF Example')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Loop Gif package:'),
                const SizedBox(height: 10),
                Gif(
                  image: const AssetImage("assets/gif/newmotor.gif"),
                  controller: controller,
                  onFetchCompleted: () {
                    final upper = controller.upperBound;
                    if (controller.duration != null) {
                      controller.repeat(
                        min: 0,
                        max: upper,
                        period: controller.duration!,
                      );
                    }
                  },
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 20),
                const Text('Normal:'),
                const SizedBox(height: 10),
                Image.asset(
                  "assets/gif/testinggif.gif",
                  height: 100,
                  width: 100,
                ),
                // const SizedBox(height: 20),
                // const Text('LoopingGif Function:'),
                // const SizedBox(height: 10),
                // const LoopingGif(
                //   assetPath: "assets/gif/dp_irr_pump_g.gif",
                //   height: 100,
                //   width: 100,
                // ),
                const Text('LK Network Image:'),
                const SizedBox(height: 10),
                Image.network('https://mir-s3-cdn-cf.behance.net/project_modules/1400/091089194042773.661d38a331980.gif',
                  height: 100,
                  width: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}