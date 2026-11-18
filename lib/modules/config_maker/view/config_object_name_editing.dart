import 'package:flutter/material.dart';
import '../model/device_object_model.dart';
import '../state_management/config_maker_provider.dart';
import '../../../Widgets/sized_image.dart';
import '../../../utils/constants.dart';

class ConfigObjectNameEditing extends StatefulWidget {
  final ConfigMakerProvider configPvd;
  final List<DeviceObjectModel> listOfObjectInLine;
  const ConfigObjectNameEditing({super.key, required this.listOfObjectInLine, required this.configPvd});

  @override
  State<ConfigObjectNameEditing> createState() => _ConfigObjectNameEditingState();
}

class _ConfigObjectNameEditingState extends State<ConfigObjectNameEditing> {
  late List<DeviceObjectModel> listOfObjectInLine;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listOfObjectInLine = widget.listOfObjectInLine.map((object)=> DeviceObjectModel.fromJson(object.toJson())).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          itemCount: listOfObjectInLine.length,
            itemBuilder: (context, index){
            return ListTile(
              leading: SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${listOfObjectInLine[index].objectId}.svg'),
              title: Text('${widget.listOfObjectInLine[index].name} --->'),
              trailing: SizedBox(
                width: 200,
                child: TextFormField(
                  initialValue: listOfObjectInLine[index].name,
                  cursorHeight: 20,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      border: OutlineInputBorder(),
                    constraints: BoxConstraints(
                      minWidth: 200,
                      maxWidth: 300,
                      minHeight: 20,
                      maxHeight: 40,
                    ),
                  ),
                  onChanged: (value){
                    setState(() {
                      listOfObjectInLine[index].name = value;
                    });
                  },
                ),
              )
            );
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedImage(imagePath: '${AppConstants.svgObjectPath}objectId_${listOfObjectInLine[index].objectId}.svg'),
                  Text('${listOfObjectInLine[index].name} --->'),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder()
                      ),
                    ),
                  )
                ],
              ),
            );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          widget.configPvd.updateName(listOfObjectInLine);
          Navigator.pop(context);
        },
        child: const Text('Save'),
      ),
    );
  }
}