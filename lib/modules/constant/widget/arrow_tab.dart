import 'package:flutter/material.dart';

enum ArrowTabState {complete, inComplete, onProgress}

class ArrowTab extends StatelessWidget {
  final int index;
  final String title;
  final ArrowTabState arrowTabState;
  const ArrowTab({super.key, required this.index, required this.title, required this.arrowTabState});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          width: arrowTabState == ArrowTabState.onProgress ? 200 : 180,
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
              width: 180,
              height: 50,
              fit: BoxFit.fill,
              color: getImageColor(context),
              colorBlendMode: BlendMode.modulate,
              'assets/Images/Png/arrow.png'
          ),
        ),
        getAvatarAndName(context),
      ],
    );
  }

  Widget getAvatarAndName(BuildContext context){
    return Positioned(
      top: 10,
      left: 20,
      child: SizedBox(
        width: 180,
        child: Row(
          spacing: 10,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: getAvatarColor(context),
              child: Center(
                child: Text('${index+1}', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14 ,overflow: TextOverflow.ellipsis, color: arrowTabState == ArrowTabState.onProgress ? Colors.white : Colors.black)),
              ),
            ),
            Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14 ,overflow: TextOverflow.ellipsis, color: arrowTabState == ArrowTabState.onProgress ? Colors.white : Colors.black),)
            )
          ],
        ),
      ),
    );
  }

  Color getImageColor(BuildContext context){
    return arrowTabState == ArrowTabState.complete
        ? const Color(0xffD1D1D1)
        : arrowTabState == ArrowTabState.onProgress
        ? Theme.of(context).primaryColor : Colors.white;
  }

  Color getAvatarColor(BuildContext context){
    return arrowTabState == ArrowTabState.complete
        ? Colors.white
        : arrowTabState == ArrowTabState.onProgress
        ? Theme.of(context).primaryColorLight : const Color(0xffD1D1D1);
  }
}
