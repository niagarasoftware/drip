import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SizedImage extends StatelessWidget {
  final String imagePath;
  Color? color;
  SizedImage({super.key, required this.imagePath, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      color: color,
      imagePath,
      width: 30,
      height: 30,
    );
  }
}

class SizedImageMedium extends StatelessWidget {
  final String imagePath;
  const SizedImageMedium({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Image.asset(imagePath),
    );
  }
}

class SizedImageSmall extends StatelessWidget {
  final String imagePath;
  Color? color;
  SizedImageSmall({super.key, required this.imagePath, this.color});

  @override
  Widget build(BuildContext context) {
    bool themeMode = Theme.of(context).brightness == Brightness.light;
    return SvgPicture.asset(
      color: color ?? (themeMode ? Colors.black : Colors.white70),
      imagePath,
      width: 20,
      height: 20,
    );
  }
}
