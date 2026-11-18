import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/Theme/smart_comm_theme.dart';

import '../flavors.dart';

class AppProperties {
  //Todo duration
  static const duration200Mill = Duration(
    milliseconds: 200,
  );

  static const primaryColorDark = Color(0xFF036673);
  static const primaryColorMedium = Color(0xFF1D808E);
  static const primaryColorLight = Color(0x644BDCEF);

  static const textColorWhite = Colors.white;
  static const textColorBlack = Colors.black;
  static const textColorGray = Colors.grey;
  //Todo text style
  static const titleTextStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      overflow: TextOverflow.ellipsis
  );
  static const normalBlackBoldTextStyle = TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis, color: Colors.black);
  static const tableHeaderStyle = TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis, fontSize: 12);
  static const tableHeaderStyleWhite = TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis, fontSize: 12, color: Colors.white);
  static const normalWhiteBoldTextStyle = TextStyle(overflow: TextOverflow.ellipsis, color: Colors.white, fontSize: 15);
  static const listTileBlackBoldStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black);

  //Todo padding style
  static const symmetric8to5 = EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  //Todo linear gradient
  static final linearGradientPrimary = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xff054750),
        const Color(0xff054750).withOpacity(0.8),
      ]
  );
  static final linearGradientPrimaryLite = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xff1C7B86),
        const Color(0xff1C7B86).withOpacity(0.8),
      ]
  );

  //Todo : box shadow
  static final List<BoxShadow> customBoxShadowLiteTheme = [
    BoxShadow(
        offset: const Offset(0,45),
        blurRadius: 112,
        color: Colors.black.withOpacity(0.06)
    ),
    BoxShadow(
        offset: const Offset(0,22.78),
        blurRadius: 48.83,
        color: Colors.black.withOpacity(0.04)
    ),
    BoxShadow(
        offset: const Offset(0,9),
        blurRadius: 18.2,
        color: Colors.black.withOpacity(0.03)
    ),
    BoxShadow(
        offset: const Offset(0,1.97),
        blurRadius: 6.47,
        color: Colors.black.withOpacity(0.02)
    ),
  ];
  static final List<BoxShadow> customBoxShadowDarkTheme = [
    BoxShadow(
        offset: const Offset(0,45),
        blurRadius: 112,
        color: Colors.white.withOpacity(0.06)
    ),
    BoxShadow(
        offset: const Offset(0,22.78),
        blurRadius: 48.83,
        color: Colors.white.withOpacity(0.04)
    ),
    BoxShadow(
        offset: const Offset(0,9),
        blurRadius: 18.2,
        color: Colors.white.withOpacity(0.03)
    ),
    BoxShadow(
        offset: const Offset(0,1.97),
        blurRadius: 6.47,
        color: Colors.white.withOpacity(0.02)
    ),
  ];


  //Todo radius
  static const Radius radius5 = Radius.circular(5);


  static LinearGradient linearGradientLeading = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: F.appFlavor!.name.contains('oro')
        ? [const Color(0xff1D808E), const Color(0xff044851)]
        : [SmartCommTheme.lightTheme.primaryColor.withOpacity(0.7), SmartCommTheme.lightTheme.primaryColorDark],
  );

  static LinearGradient linearGradientLeading2 = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: F.appFlavor!.name.contains('oro')
        ? [const Color(0xff1D808E), const Color(0xff044851)]
        : [SmartCommTheme.lightTheme.primaryColor.withOpacity(0.7), SmartCommTheme.lightTheme.primaryColorDark],
  );

  static LinearGradient redLinearGradientLeading = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.red.shade300, Colors.red.shade700],
  );

  static LinearGradient greenLinearGradientLeading = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.green.shade300, Colors.green.shade700],
  );

  static Widget buildActionButton(
      {required BuildContext context, required String key, required IconData icon, required String label,
        required VoidCallback onPressed, Color? buttonColor, Color? labelColor, BorderRadius? borderRadius}) {
    return IconButton(
      key: Key(key),
      onPressed: onPressed,
      // color: buttonColor ?? Colors.white,
      // elevation: 1,
      // shape: RoundedRectangleBorder(
      //     borderRadius: borderRadius ?? BorderRadius.circular(15)
      // ),
      icon: Icon(icon, color: labelColor,),
    );
  }

  static Widget buildSideBarMenuList(
      {required BuildContext context, BoxConstraints? constraints, required dataList,
        required String title, required index, icons, required bool selected, required void Function(int) onTap, Widget? child}) {
    return Material(
      type: MaterialType.transparency,
      child: MediaQuery.of(context).size.width > 600 ?
      IntrinsicWidth(
        stepWidth: constraints!.maxWidth * 0.15,
        child: ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width > 600 ? 12 : 25)
            ),
            title: child ?? Text(title, style: TextStyle(color: selected ? MediaQuery.of(context).size.width > 600 ? Colors.white : Colors.white : Theme.of(context).primaryColor),),
            leading: icons != null ? Icon(icons[index], color: Colors.white,) : null,
            selected: selected,
            onTap: () {
              onTap(index);
            },
            selectedTileColor: selected ? Theme.of(context).primaryColor  : null,
            hoverColor: selected ? Theme.of(context).primaryColor : null
        ),
      ) :
      InkWell(
          onTap: () {
            onTap(index);
          },
          // borderRadius: BorderRadius.circular(20),
          child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: EdgeInsets.symmetric(horizontal: child == null ? 20: 10, vertical: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  // boxShadow: customBoxShadow2,
                  // gradient: selected ? linearGradientLeading : null,
                  border: Border.all(color: Theme.of(context).primaryColor, width: 0.3),
                  color: selected
                      ? const Color(0xffF2F2F2)
                      : Theme.of(context).primaryColor
              ),
              child: Center(
                  child: child ?? Text(title, style: TextStyle(color: !selected ? Colors.white : Theme.of(context).primaryColor),)
              )
          )
      ),
    );
  }

  static dynamic regexForNumbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))];
  static dynamic regexForDecimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),];
  static TextStyle cardTitle = const TextStyle(fontSize: 13);
  static List<String> yesNoList = ['Yes','No'];

}