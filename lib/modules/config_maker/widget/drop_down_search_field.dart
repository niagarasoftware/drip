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
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Search available ${widget.oldDevice['categoryName'] ?? 'device'} from stock to replace current device:',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 16),
              DropDownSearchFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _dropdownSearchFieldController,
                  decoration: InputDecoration(
                    labelText: 'Select New Device ID',
                    hintText: 'Type device ID to search...',
                    prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                ),
                suggestionsCallback: (pattern) {
                  return getSuggestions(pattern);
                },
                itemBuilder: (context, String suggestion) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.developer_board_rounded, color: Theme.of(context).primaryColor, size: 18),
                    ),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xff1E293B)),
                    ),
                  );
                },
                itemSeparatorBuilder: (context, index) {
                  return Divider(height: 1, color: Colors.grey.shade200);
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xff475467))),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.find_replace_outlined, size: 18),
                    label: const Text('Replace Device'),
                    onPressed: () async{
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }
                      int statusCode = await configPvd.replaceDevice(
                        newDevice: widget.productStock.firstWhere((device) => device['deviceId'] == _dropdownSearchFieldController.text),
                        oldDevice: widget.oldDevice,
                        masterOrNode: widget.masterOrNode,
                      );
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
                          message: "Device replaced successfully",
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
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
