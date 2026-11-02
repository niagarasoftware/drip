// lib/main.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/servicecustomermodel.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/snack_bar.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';



class TicketHomePage extends StatefulWidget {
  final int userId, controllerId;
  const TicketHomePage({
    super.key,
    required this.userId,
    required this.controllerId,
  });

  @override
  State<TicketHomePage> createState() => _TicketHomePageState();
}

class _TicketHomePageState extends State<TicketHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otherstextctrl = TextEditingController();

  RequestType _selectedCategory = RequestType();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  DateFormat timeformat = DateFormat("HH:mm:ss");
  DateFormat exceptDateFormat = DateFormat("yyyy-MM-dd");

  ServicecustomerModel _servicecustomerModel = ServicecustomerModel();
  String dropdownvalue = 'Controller Regarding';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Safe place to use Provider with context
    fetchData();
  }

  Future<void> fetchData() async {
    // if you don’t use this, remove it
    // var overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    // AppLog.log("userId ${widget.userId} controllerId ${widget.controllerId}");

    final prefs = await SharedPreferences.getInstance();
    try {
      final Repository repository = Repository(HttpService());
      var getUserDetails = await repository.getUserServiceRequest({
        "userId": widget.userId,
        "controllerId": widget.controllerId
      });

      AppLog.log("userId ${widget.userId} controllerId ${widget.controllerId}");
      // AppLog.log("getUserDetails.body ${getUserDetails.body}");

      if (getUserDetails.statusCode == 200) {
        var jsonData = jsonDecode(getUserDetails.body);
        if (!mounted) return; // ✅ avoid setState on unmounted widget
        setState(() {
          _servicecustomerModel = ServicecustomerModel.fromJson(jsonData);
        });
      } else {
        // GlobalSnackBar.show(context, "Failed to fetch", getUserDetails.statusCode);
      }
    } catch (e, stackTrace) {
      AppLog.log(' Error overAll getData => ${e.toString()}');
      AppLog.log(' trace overAll getData  => $stackTrace');
    }
  }

  Future<void> updateData(
      int requestTypeId,
      String requestDate,
      String requestDescription,
      String requestTime,
      int responsibleUser,
      String estimatedDate,
      ) async {
    AppLog.log('call update');
    otherstextctrl.clear();

    Map<String, Object> body = {
      "userId": widget.userId,
      "controllerId": widget.controllerId,
      "requestTypeId": requestTypeId,
      "requestDescription": requestDescription,
      "requestDate": requestDate,
      "requestTime": requestTime,
      "responsibleUser": responsibleUser,
      "estimatedDate": estimatedDate,
      "siteLocation": '',
      "createUser": widget.userId
    };

    final Repository repository = Repository(HttpService());
    var response = await repository.createUserServiceRequest(body);
    var jsonData = jsonDecode(response.body);
    AppLog.log('jsonData:$jsonData');

    if (!mounted) return; // ✅ check before using context

    if (response.statusCode == 200) {
      setState(() {
        GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
        fetchData();
      });
    } else {
      GlobalSnackBar.show(context, jsonData['message'], response.statusCode);
    }
  }

  @override
  void dispose() {
    otherstextctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_servicecustomerModel.data == null) {
      return const Center(
        child: Text(
          'Currently no repository Request available ',
          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
        ),
      );
    } else if (_servicecustomerModel.data!.dataDefault!.requestType!.isEmpty) {
      return const Center(
        child: Text(
          'Currently repository Request Not available in your Account',
          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: kIsWeb ? null : AppBar(title: const Text('Service Request')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    DropdownButton(
                      iconSize: 32,
                      dropdownColor: Colors.grey.shade50,
                      value: dropdownvalue,
                      icon: const Icon(Icons.arrow_drop_down_sharp),
                      items: _servicecustomerModel
                          .data!.dataDefault!.requestType!
                          .map((items) {
                        return DropdownMenuItem(
                          value: items.requestType,
                          child: Text(items.requestType!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownvalue = newValue!;
                          _selectedCategory = _servicecustomerModel
                              .data!.dataDefault!.requestType!
                              .firstWhere(
                                  (e) => e.requestType == newValue);
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: TextFormField(
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 5) {
                            return 'Please Enter a Valid Reason';
                          }
                          return null;
                        },
                        maxLength: 200,
                        controller: otherstextctrl,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _selectedCategory.requestType,
                          hintText: 'Explain here',
                        ),
                        autofocus: true,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState != null &&
                            _formKey.currentState!.validate()) {
                          updateData(
                            _selectedCategory.requestTypeId ?? 3,
                            dateFormat.format(DateTime.now()),
                            otherstextctrl.text,
                            timeformat.format(DateTime.now()),
                            _servicecustomerModel
                                .data!.dataDefault!.dealer![0].userId!,
                            exceptDateFormat.format(
                              DateTime.now().add(const Duration(days: 2)),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Raise Ticket',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      direction: Axis.horizontal,
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        for (var index = 0;
                        index <
                            _servicecustomerModel
                                .data!.serviceRequest!.length;
                        index++)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              boxShadow: customBoxShadow,
                            ),
                            height: 250,
                            width: 250,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IntrinsicHeight(
                                  child: Center(
                                    child: Text(
                                      '${_servicecustomerModel.data!.serviceRequest![index].requestType}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 21,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 60,
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Text(
                                      '${_servicecustomerModel.data!.serviceRequest![index].requestDescription}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_servicecustomerModel.data!.serviceRequest![index].requestDate} ${_servicecustomerModel.data!.serviceRequest![index].requestTime}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  'Expectation Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xff15C0E6),
                                  ),
                                ),
                                Text(
                                  '${_servicecustomerModel.data!.serviceRequest![index].estimatedDate}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Responsibility:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xff15C0E6),
                                  ),
                                ),
                                Text(
                                  '${_servicecustomerModel.data!.serviceRequest![index].responsibleUserName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_servicecustomerModel.data!.serviceRequest![index].status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 21,
                                    color: '${_servicecustomerModel.data!.serviceRequest![index].responsibleUserName}' ==
                                        'Waiting'
                                        ? const Color(0xfff3bf21)
                                        : '${_servicecustomerModel.data!.serviceRequest![index].responsibleUserName}' ==
                                        'Completed'
                                        ? const Color(0xff21f33d)
                                        : const Color(0xff1c7b89),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

List<BoxShadow> customBoxShadow = [
  BoxShadow(
    offset: const Offset(0, 45),
    blurRadius: 112,
    color: Colors.black.withValues(alpha: 0.06),
  ),
  BoxShadow(
    offset: const Offset(0, 22.78),
    blurRadius: 48.83,
    color: Colors.black.withValues(alpha: 0.0405),
  ),
  BoxShadow(
    offset: const Offset(0, 9),
    blurRadius: 18.2,
    color: Colors.black.withValues(alpha: 0.03),
  ),
  BoxShadow(
    offset: const Offset(0, 1.97),
    blurRadius: 6.47,
    color: Colors.black.withValues(alpha: 0.0195),
  ),
];
