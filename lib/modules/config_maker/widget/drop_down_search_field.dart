import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/dialog_boxes.dart';
import 'package:provider/provider.dart';

import '../state_management/config_maker_provider.dart';

class DropDownSearchField extends StatefulWidget {
  final List<dynamic> productStock;
  final Map<String, dynamic> oldDevice;
  final int masterOrNode;

  DropDownSearchField({super.key, required this.productStock, required this.oldDevice, required this.masterOrNode});

  @override
  _DropDownSearchFieldState createState() => _DropDownSearchFieldState();
}

class _DropDownSearchFieldState extends State<DropDownSearchField> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dropdownSearchFieldController = TextEditingController();

  String? _selectedFruit;

  SuggestionsBoxController suggestionBoxController = SuggestionsBoxController();

  List<String> getSuggestions(String query) {
    List<String> matches = <String>[];
    matches.addAll(widget.productStock
        .where((device) => device['modelId'] == widget.oldDevice["modelId"])
        .map((device) => device['deviceId'].toString())
        .toList());
    print('matches : $matches');
    matches.retainWhere((s) => s.toLowerCase().contains(query.toLowerCase()));
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    var configPvd = Provider.of<ConfigMakerProvider>(context, listen: true);
    return GestureDetector(
      onTap: () {
        suggestionBoxController.close();
      },
      child: SizedBox(
        height: 150,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Search Device to replace'),
              DropDownSearchFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  decoration: InputDecoration(labelText: widget.oldDevice['categoryName']),
                  controller: _dropdownSearchFieldController,
                ),
                suggestionsCallback: (pattern) {
                  return getSuggestions(pattern);
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                itemSeparatorBuilder: (context, index) {
                  return const Divider();
                },
                transitionBuilder: (context, suggestionsBox, controller) {
                  return suggestionsBox;
                },
                onSuggestionSelected: (String suggestion) {
                  _dropdownSearchFieldController.text = suggestion;
                },
                suggestionsBoxController: suggestionBoxController,
                validator: (value) =>
                value!.isEmpty ? 'Please select a device' : null,
                onSaved: (value) => _selectedFruit = value,
                displayAllSuggestionWhenTap: true,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel')
                  ),
                  const SizedBox(width: 10,),
                  FilledButton.icon(
                    icon: const Icon(Icons.find_replace_outlined),
                    label: const Text('Replace'),
                    onPressed: () async{
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // Optionally use `_selectedFruit` here
                      }
                      int statusCode = await configPvd.replaceDevice(newDevice: widget.productStock.firstWhere((device) => device['deviceId'] == _dropdownSearchFieldController.text), oldDevice: widget.oldDevice, masterOrNode: widget.masterOrNode);
                      if(statusCode == 200){
                        for(var device in widget.productStock){
                          if(device["deviceId"] == _dropdownSearchFieldController.text){
                            setState(() {
                              device["deviceId"] = widget.oldDevice["deviceId"];
                            });
                          }
                        }
                        Navigator.pop(context);
                        simpleDialogBox(
                          context: context,
                          title: 'Success',
                          message: "Device replace Successfully",
                        );
                      }else{
                        Navigator.pop(context);
                        simpleDialogBox(
                          context: context,
                          title: 'Alert',
                          message: "Device replace failed",
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
