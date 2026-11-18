import 'package:flutter/material.dart';
import '../../../../view_models/customer/condition_library_view_model.dart';

Widget buildAlertMessageField(
    BuildContext context, ConditionLibraryViewModel vm, int index) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: TextFormField(
      maxLength: 100,
      controller: vm.amTEVControllers[index],
      decoration: const InputDecoration(
        counterText: '',
        labelText: 'Alert message',
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please fill out this field';
        }
        return null;
      },
    ),
  );
}