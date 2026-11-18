import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer/sent_and_received_model.dart';
import '../../repository/repository.dart';
import '../../utils/shared_preferences_helper.dart';

class SentAndReceivedViewModel extends ChangeNotifier {
  final Repository repository;

  int? customerId;
  int? controllerId;
  bool? isWide;

  bool _disposed = false;
  bool isLoading = false;
  String errorMessage = "";
  List<SentAndReceivedModel> sentAndReceivedList = [];

  bool hasPayloadViewPermission = false;
  TextEditingController passwordController = TextEditingController();

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  SentAndReceivedViewModel(this.repository);

  void initIds({
    required int customerId,
    required int controllerId,
    bool? isWide,
  }) {
    this.customerId = customerId;
    this.controllerId = controllerId;
    this.isWide = isWide;
  }

  @override
  void dispose() {
    _disposed = true;
    passwordController.dispose();
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    safeNotify();
  }

  Future<void> getSentAndReceivedData(String date) async {
    setLoading(true);
    String? userRole = await PreferenceHelper.getUserRole();
    if (userRole != 'customer') {
      hasPayloadViewPermission = true;
    }

    try {
      final body = {
        "userId": customerId,
        "controllerId": controllerId,
        "fromDate": date,
        "toDate": date,
      };

      final response = await repository.fetchSentAndReceivedData(body);

      if (_disposed) return; // 👈 prevent updates after dispose

      if (response.statusCode == 200) {
        sentAndReceivedList.clear();
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          sentAndReceivedList = (jsonData['data'] as List)
              .map((programJson) =>
              SentAndReceivedModel.fromJson(programJson))
              .toList();
        }
      }
    } catch (error) {
      debugPrint('Error fetching sent/received data: $error');
    } finally {
      if (!_disposed) setLoading(false);
    }
  }

  Future<void> getUserSoftwareOrHardwarePayload(
      BuildContext context,
      int sentAndReceivedId,
      String aTitle,
      String pyTitle,
      ) async {
    var body = {
      "userId": customerId,
      "controllerId": controllerId,
      "sentAndReceivedId": sentAndReceivedId,
    };

    try {
      final response =
      await repository.fetchSentAndReceivedHardwarePayload(body);

      if (_disposed) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["code"] == 200) {
          final message = jsonData['data']?['message'];

          if (message != null) {
            displayJsonData(
                context, jsonData['data'], aTitle, pyTitle);
          } else {
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(aTitle),
                  content: const Text("No data available."),
                  actions: [
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (error) {
      debugPrint('Error fetching payload: $error');
    } finally {
      if (!_disposed) setLoading(false);
    }
  }

  void displayJsonData(
      BuildContext context,
      Map<String, dynamic> jsonData,
      String aTitle,
      String pyTitle,
      ) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(aTitle),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pyTitle, style: const TextStyle(color: Colors.teal)),
                  const Divider(),
                  SelectableText(
                    jsonEncode(jsonData['message']),
                    style: const TextStyle(color: Colors.black54),
                    showCursor: true,
                  ),
                  if (jsonData['changedPayload'] != null) ...[
                    const SizedBox(height: 8),
                    const Text('Modified Settings',
                        style: TextStyle(color: Colors.teal)),
                    const Divider(),
                    SelectableText(
                      jsonEncode(jsonData['changedPayload']),
                      style: const TextStyle(color: Colors.black54),
                      showCursor: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String convertTo12hrs(String timeString) {
    final dateTime = DateFormat("HH:mm:ss").parse(timeString);
    return DateFormat("h:mm a").format(dateTime);
  }

  void onDateChanged(DateTime sDate, DateTime fDate) {
    selectedDay = sDate;
    focusedDay = fDate;
    String formattedDate = DateFormat('yyyy-MM-dd').format(sDate);
    getSentAndReceivedData(formattedDate);
  }
}