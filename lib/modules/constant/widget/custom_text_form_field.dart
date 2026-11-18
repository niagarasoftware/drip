import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';

class CustomTextFormField extends StatefulWidget {
  final String value;
  final String dataType;
  final void Function(String)? onChanged;
  const CustomTextFormField({super.key, required this.value, required this.dataType,required this.onChanged});

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool isEditing = false;
  FocusNode myFocus = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        myFocus.addListener(() {
          if(!myFocus.hasFocus){
            toggleEditing();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    myFocus.dispose();
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        myFocus.requestFocus();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleEditing,
      child: isEditing ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2))
        ),
        child: TextFormField(
          // inputFormatters: widget.dataType.contains('int') ? AppProperties.regexForNumbers : AppProperties.regexForDecimal,
          focusNode: myFocus,
          initialValue: widget.value,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            constraints: BoxConstraints(
              maxHeight: 40
            ),
              contentPadding: EdgeInsets.all(0) ,
            border: OutlineInputBorder(
              borderSide: BorderSide.none
            )
          ),

        ),
      ) : Container(
          margin: const EdgeInsets.all(2),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          height: double.infinity,
          child: Center(child: Text(widget.value, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w600),))
      ),
    );
  }
}
