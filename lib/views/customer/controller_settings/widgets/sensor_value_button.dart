import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../view_models/customer/condition_library_view_model.dart';

class SensorValueButton extends StatelessWidget {
  final ConditionLibraryViewModel vm;
  final int index;
  final Function(String) onValueChanged;
  final TextEditingController controller;


  const SensorValueButton({super.key, required this.index, required this.vm, required this.controller, required this.onValueChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 27,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(width: 0.5, color: Colors.grey.shade400),
      ),
      child: TextButton(
        onPressed: () => _showInputDialog(context),
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          minimumSize: WidgetStateProperty.all(Size.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(
          vm.clData.cnLibrary.condition[index].value,
          style: const TextStyle(color: Colors.black, fontSize: 13),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select values and Operator'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: SizedBox(
            width: kIsWeb? 250 : 300,
            height: kIsWeb? 260 : 300,
            child: Column(
              children: [
                SizedBox(
                  width: kIsWeb? 260 : 300,
                  height: 50,
                  child: TextFormField(
                    controller: controller,
                    maxLength: 100,
                    readOnly: true,
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: 'Value/Threshold',
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
                ),
                const SizedBox(height: 8),
                _buildGridView(context),
                SizedBox(
                  width: kIsWeb? 260 : 300,
                  height: 50,
                  child: Row(
                    children: [
                      MaterialButton(
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        height: 40,
                        minWidth: kIsWeb? 170 : 200,
                        onPressed: () {
                          controller.text += ' ';
                        },
                        child: const Text('Space'),
                      ),
                      const SizedBox(width: 5),
                      MaterialButton(
                        height: 40,
                        color: Theme.of(context).primaryColorLight,
                        textColor: Colors.white,
                        onPressed: () {
                          if (controller.text.trim().isEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text("Field cannot be empty or contain only spaces."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            onValueChanged(controller.text);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Enter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    List<String> operators = ['%', '°C', '.', 'cl', 'C', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];
    return SizedBox(
      width: kIsWeb? 260 : 300,
      height: kIsWeb? 150: 190,
      child: GridView.count(
        crossAxisCount: 5,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: operators.map((operator) {
          return ElevatedButton(
            onPressed: () {
              if (operator == 'C') {
                controller.clear();
              } else if (operator == 'cl') {
                if (controller.text.isNotEmpty) {
                  controller.text = controller.text.substring(0, controller.text.length - 1);
                }
              } else {
                controller.text += operator;
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                operator == 'C' ? Colors.redAccent : Theme.of(context).primaryColor,
              ),
            ),
            child: operator == 'cl'
                ? const Icon(Icons.backspace_outlined, color: Colors.white)
                : Text(operator, style: TextStyle(fontSize: 15, color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }

}