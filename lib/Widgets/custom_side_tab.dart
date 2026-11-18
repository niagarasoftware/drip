import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Widgets/sized_image.dart';
import '../Constants/properties.dart';

class CustomSideTab extends StatelessWidget {
  final bool selected;
  final double width;
  final String imagePath;
  final String title;
  final void Function()? onTap;
  const CustomSideTab({
    super.key,
    required this.width,
    required this.imagePath,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('selected : $selected');
    bool themeMode = Theme.of(context).brightness == Brightness.light;
    Widget myChild =  Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: width,
      decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColorLight.withOpacity(themeMode ? 1.0 : 0.5) : null,
          borderRadius: BorderRadius.circular(8)
      ),
      child: ListTile(
        contentPadding: width < 100 ? const EdgeInsets.symmetric(horizontal: 8,vertical: 4) : null,
        onTap: onTap,
        title: width < 100 ? null : Text(title,style: AppProperties.normalWhiteBoldTextStyle,),
        leading: SizedImage(imagePath: imagePath,),
      ),
    );
    if(width < 100){
      return Tooltip(
        message: title,
        decoration: const BoxDecoration(
            color: Colors.black
        ),
        textStyle: AppProperties.normalWhiteBoldTextStyle,
        child: myChild,
      );
    }else{
      return myChild;
    }
  }

}
