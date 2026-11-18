import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/utils/shared_preferences_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/http_service.dart';
import '../repository/user_chat_repo.dart';

class UserChatScreen extends StatefulWidget {
  final int userId;
  final String userName, phoneNumber;
  const UserChatScreen({super.key, required this.userId, required this.userName, required this.phoneNumber});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  List messages = [];
  List chatIds = [];
  String errorMessage = '';
  int dealerId = 0;
  String dealerName = "";
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateTime time = DateTime.now();
  String phoneNumber = '';
  final UserChatRepository repository = UserChatRepository(HttpService());
  bool isDealer = false;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      getData();
    }
  }

  Future<void> getData() async {
    await getUserDealerDetails();
    await getUserChat();
    updateUserChatReadStatus();
  }

  Future<void> getUserDealerDetails() async {
    Map<String, dynamic> userData = {
      "userId": widget.userId,
    };

    try {
      final getUserDealerDetails = await repository.getUserDealerDetails(userData);
      final userRole = await PreferenceHelper.getUserRole();
      if (getUserDealerDetails.statusCode == 200) {
        setState(() {
          final response = jsonDecode(getUserDealerDetails.body);
          if (response['code'] == 200) {
            // print("userRole ::: ${userRole.runtimeType}");
            isDealer = userRole == '2' || userRole == '1';
            dealerId = response['data']['userId'];
            dealerName = response['data']['userName'];
            phoneNumber = response['data']['mobileNumber'] ?? "1234567890";
          } else {
            errorMessage = response['message'];
          }
        });
      }
    } catch (error, stackTrace) {
      // print("Error in the user chat: $error");
      // print("Stack trace in user chat: $stackTrace");
    }
  }

  Future<void> getUserChat() async {
    Map<String, dynamic> userData = {
      "fromUserId": isDealer ? dealerId: widget.userId,
      "toUserId": isDealer ? widget.userId : dealerId,
    };

    // print("userdata in the chat :: $userData");
    try {
      final getUserChat = await repository.getUserChat(userData);
      if (getUserChat.statusCode == 200) {
        chatIds.clear();
        setState(() {
          final response = jsonDecode(getUserChat.body);
          if (response['code'] == 200) {
            messages = response['data'];
            messages.forEach((element) {
              if(((isDealer ? dealerId : widget.userId) == element['toUserId']) && element['readStatus'] == "0") {
                chatIds.add(element['chatId']);
              }
            });
            // print("getUserChat");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            });
            // print("chatIds ==> $chatIds");
          } else {
            errorMessage = response['message'];
          }
        });
      }
    } catch (error, stackTrace) {
      // print("Error in the user chat: $error");
      // print("Stack trace in user chat: $stackTrace");
    }
  }

  Future<void> updateUserChatReadStatus() async {
    Map<String, dynamic> userData = {
      "chatId": chatIds,
      "toUserId": isDealer ? dealerId : widget.userId,
      "fromUserId": isDealer ? widget.userId : dealerId,
    };
    try {
      final updateUserChatReadStatus = await repository.updateUserChatReadStatus(userData);
      if (updateUserChatReadStatus.statusCode == 200) {
        setState(() {
          final response = jsonDecode(updateUserChatReadStatus.body);
          if (response['code'] == 200) {
            // print("updateUserChatReadStatus");
          } else {
            errorMessage = response['message'];
          }
        });
      }
    } catch (error, stackTrace) {
      // print("Error in the user chat: $error");
      // print("Stack trace in user chat: $stackTrace");
    }
  }

  Future<void> createUserChat() async {
    Map<String, dynamic> userData = {
      "fromUserId": isDealer ? dealerId : widget.userId,
      "toUserId": isDealer ? widget.userId : dealerId,
      "date": DateFormat("yyyy-MM-dd").format(time),
      "time": DateFormat("HH:mm:ss").format(time),
      "message": _messageController.text,
    };
// print('userData:$userData');

    try {
      final createUserChat = await repository.createUserChat(userData);
      setState(() {
        if (createUserChat.statusCode == 200) {
          _messageController.clear();
          getUserChat().whenComplete(() {
            updateUserChatReadStatus();
          });
        } else {
          errorMessage = jsonDecode(createUserChat.body)['message'];
        }
      });
    } catch (error, stackTrace) {
      // print("Error in the user chat: $error");
      // print("Stack trace in user chat: $stackTrace");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
  }

  void _sendMessage() {
    final messageText = _messageController.text;
    if (messageText.isNotEmpty) {
      createUserChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(isDealer ? widget.userName : dealerName, style: const TextStyle(color: Colors.white),),
          subtitle: Text(isDealer ? widget.phoneNumber : phoneNumber, style: const TextStyle(color: Colors.white54)),
        ),
        actions: [
          IconButton(
              onPressed: () async{
                final call = Uri.parse('tel:${isDealer ? widget.phoneNumber : phoneNumber}');
                if (await canLaunchUrl(call)) {
                  launchUrl(call);
                } else {
                  throw 'Could not launch $call';
                }
                // launchDialer(phoneNumber);
              },
              icon: const Icon(Icons.call, color: Colors.white)
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getData,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              if(messages.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final message = messages[index];
                      final isUserMessage = message['fromUserId'] == (isDealer ? dealerId : widget.userId);

                      DateTime messageDate = DateTime.parse(message['date']);
                      DateTime messageDateTime = DateTime.parse("${message['date']} ${message['time']}");
                      String formattedTime = DateFormat("hh:mm a").format(messageDateTime);
                      bool showDateHeader = false;

                      if (index == 0 || messageDate != DateTime.parse(messages[index - 1]['date'])) {
                        showDateHeader = true;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Text(
                                  DateFormat("EEEE, dd MMM yyyy").format(messageDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    decoration: BoxDecoration(
                                      color: isUserMessage ? Colors.blueAccent : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message['message'],
                                      style: TextStyle(color: isUserMessage ? Colors.white : Colors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  if (isUserMessage && message['readStatus'] == "1")
                                    const Icon(
                                      Icons.done_all,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text("Chat not yet started"),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Type your message",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              gapPadding: 0
                          ),
                        ),
                        onSubmitted: (text) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async{
                        _sendMessage();
                        // print(messages);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
