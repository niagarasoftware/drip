import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../utils/constants.dart';

class OroLoginHeader extends StatelessWidget {
  const OroLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: (MediaQuery.of(context).size.height / 2) - 100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Image(
            image: AssetImage('assets/png/oro_logo_white.png'),
            height: 70,
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              AppConstants.appShortContent,
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class ATelLoginHeader extends StatelessWidget {
  const ATelLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: (MediaQuery.of(context).size.height / 2) - 100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Image(
            image: AssetImage('assets/png/agritel_logo_white.png'),
            height: 70,
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              AppConstants.appShortContent,
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class LkLoginHeader extends StatelessWidget {
  const LkLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          width: double.infinity,
          child: const Image(
            image: AssetImage('assets/png/lk_login_left_picture.png'),
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: 5,
          right: 1,
          width: 210,
          height: 130,
          child: SvgPicture.asset(
            'assets/svg_images/lk_login_top_corner.svg',
            fit: BoxFit.contain,
          ),
        ),
        const Positioned(
          bottom: 10,
          left: 25,
          right: 25,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Text(
              AppConstants.appShortContent,
              style: TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}