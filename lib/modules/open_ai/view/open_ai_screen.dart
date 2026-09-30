import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oro_drip_irrigation/services/image_verification_service.dart';
import '../../../cropAdvisory/view/crop_list_screen.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key, required this.userId, required this.controllerId});
  final userId, controllerId;
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final bool _isListening = false;
  File? _selectedImage;
  String? _imageSource;
  List<Chat> _chatHistory = [];
  String _currentChatId = '';
  final ScrollController _scrollController = ScrollController();
  String _selectedLanguage = "English";
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _loadChatHistory();
    _loadLanguage();
    // _initSpeech();
  }

  Future<void> _initPermissions() async {
    await [Permission.camera, Permission.photos, Permission.microphone].request();
  }

  /*Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) => _showError('Speech recognition error: $error'),
    );
    if (!available) {
      _showError('Speech recognition not available');
    }
  }*/

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatList = prefs.getStringList('chat_history') ?? [];
    setState(() {
      _chatHistory = chatList
          .map((chat) => Chat.fromJson(jsonDecode(chat)))
          .toList()
          .reversed
          .toList();
      if (_chatHistory.isNotEmpty) {
        _currentChatId = _chatHistory.first.id;
        _loadMessages(_currentChatId);
      } else {
        _startNewChat();
      }
    });
  }

  Future<void> _loadMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final messageList = prefs.getStringList('messages_$chatId') ?? [];
    setState(() {
      _messages = messageList.map((msg) => Message.fromJson(jsonDecode(msg))).toList();
    });
    _scrollToBottom();
  }

  Future<void> _saveMessage(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_editingMessage != null && _editingMessage!.timestamp == message.timestamp) {
        final index = _messages.indexWhere((m) => m.timestamp == message.timestamp);
        if (index != -1) {
          _messages[index] = message;
        }
        _editingMessage = null;
      } else {
        _messages.add(message);
      }
    });
    final messageList = _messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('messages_$_currentChatId', messageList);
    _updateChatHistory();
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatList = _chatHistory.map((chat) => jsonEncode(chat.toJson())).toList();
    await prefs.setStringList('chat_history', chatList);
  }

  void _updateChatHistory() {
    final chatIndex = _chatHistory.indexWhere((chat) => chat.id == _currentChatId);
    if (chatIndex != -1 && _messages.isNotEmpty) {
      setState(() {
        _chatHistory[chatIndex] = Chat(
          id: _currentChatId,
          title: _messages.first.text != null && _messages.first.text!.isNotEmpty
              ? (_messages.first.text!.length > 30
              ? '${_messages.first.text!.substring(0, 30)}...'
              : _messages.first.text!)
              : _messages.first.isImage
              ? 'Image Message'
              : _messages.first.isVoice
              ? 'Voice Message'
              : (_messages.first.content.length > 30
              ? '${_messages.first.content.substring(0, 30)}...'
              : _messages.first.content),
          lastModified: DateTime.now(),
        );
      });
      _saveChatHistory();
    }
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
      _messages = [];
      _chatHistory.insert(
        0,
        Chat(
          id: _currentChatId,
          title: 'New Chat',
          lastModified: DateTime.now(),
        ),
      );
    });
    _saveChatHistory();
  }

  Future<void> _deleteChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatHistory.removeWhere((chat) => chat.id == chatId);
      if (_currentChatId == chatId) {
        _messages = [];
        if (_chatHistory.isNotEmpty) {
          _currentChatId = _chatHistory.first.id;
          _loadMessages(_currentChatId);
        } else {
          _startNewChat();
        }
      }
    });
    await prefs.remove('messages_$chatId');
    await _saveChatHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // print('Max Scroll Extent: ${_scrollController.position.maxScrollExtent}');
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty && _selectedImage == null && !_isListening) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedImage != null) {
        // Verify if it's a crop image using ML Kit (Offline)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifying image...'), duration: Duration(seconds: 1)),
        );

        // final bool isCrop = await ImageVerificationService.isCropImage(_selectedImage!.path);
        final bool isCrop = true;

        if (!isCrop) {
          if (mounted) {
            _showError("The selected image does not appear to be a crop or plant. Please provide a clear photo of your crop.");
          }
          setState(() {
            _selectedImage = null;
            _imageSource = null;
            _isLoading = false;
          });
          return;
        }

        final bytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        final userMessage = Message(
          role: 'user',
          content: base64Image,
          isImage: true,
          source: _imageSource,
          text: _controller.text.isNotEmpty ? _controller.text : null,
          timestamp: _editingMessage?.timestamp ?? DateTime.now(),
          chatId: _currentChatId,
        );
        await _saveMessage(userMessage);
        await _sendImageMessage(base64Image, userMessage);
        setState(() {
          _selectedImage = null;
          _imageSource = null;
          _controller.clear();
        });
      } else if (_controller.text.isNotEmpty) {
        final userMessage = Message(
          role: 'user',
          content: _controller.text,
          timestamp: _editingMessage?.timestamp ?? DateTime.now(),
          chatId: _currentChatId,
        );
        await _saveMessage(userMessage);
        await _sendTextMessage(userMessage.content);
        setState(() => _controller.clear());
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /*Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onStatus: (status) => setState(() => _isListening = status == 'listening'),
        onError: (error) => _showError('Speech recognition error: $error'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              if (result.finalResult) {
                _isListening = false;
                _sendMessage();
              }
            });
          },
          localeId: _selectedLanguage.toLowerCase() == 'english' ? 'en_US' : 'ta_IN', // Add more mappings as needed
        );
      } else {
        _showError('Speech recognition not available');
      }
    }
  }*/

  Future<void> _sendTextMessage(String text) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer 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', // Replace with your API key
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          "role": "system",
          "content": "You are an expert crop advisor. Always respond only in $_selectedLanguage. Analyze any provided data and provide a detailed diagnosis of any visible crop issues. Give actionable recommendations to improve yield or treat the problem. Identify crop type and predict the days of the crop. Suggest crop advisory, fertilizer, and watering recommendations."
        },
        {'role': 'user', 'content': text}
      ],
    });

    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = Message(
            role: 'assistant',
            content: data['choices'][0]['message']['content'],
            timestamp: DateTime.now(),
            chatId: _currentChatId,
            enableAnimation: true
        );
        await _saveMessage(assistantMessage);
      } else {
        _showError('Text request failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _sendImageMessage(String base64Image, Message userMessage) async {
    final headers = {
      'Authorization': 'Bearer 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', // Replace with your API key
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          "role": "system",
          "content": "You are an expert crop advisor. Your name is Niagara AI. Analyze the uploaded image and provide a detailed diagnosis of any visible crop issues. Give actionable recommendations to improve yield or treat the problem, even if image is the only data available. Identify crop type and predict the days of the crop. Suggest crop advisory, fertilizer, and watering recommendations in $_selectedLanguage."
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            },
            {
              'type': 'text',
              'text': userMessage.text?.isNotEmpty == true
                  ? "${userMessage.text} Please analyze this image and help me diagnose my crop issue and suggest improvements. Identify crop type and predict the days of the crop. Suggest crop advisory, fertilizer, and watering recommendations in $_selectedLanguage."
                  : "Please analyze this image and help me diagnose my crop issue and suggest improvements. Identify crop type and predict the days of the crop. Suggest crop advisory, fertilizer, and watering recommendations in $_selectedLanguage.",
            },
          ],
        },
      ],
      'max_tokens': 300,
    });

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = Message(
            role: 'assistant',
            content: data['choices'][0]['message']['content'],
            timestamp: DateTime.now(),
            chatId: _currentChatId,
            enableAnimation: true
        );
        await _saveMessage(assistantMessage);
      } else {
        _showError('Image request failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!await _requestPermissions()) {
      _showError('Permission denied');
      return;
    }

    final image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageSource = source == ImageSource.camera ? 'camera' : 'gallery';
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString("language") ?? "English";
    });
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", lang);
    setState(() {
      _selectedLanguage = lang;
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["English", "Tamil", "Tanglish", "Hindi", "Malayalam", "Telugu", "Kannada"].map((lang) {
              return RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  if (value != null) {
                    _setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _editMessage(Message message) {
    setState(() {
      _editingMessage = message;
      _controller.text = message.text ?? message.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Colors.blueAccent],
                ),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chat History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                _startNewChat();
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.chat),
                    title: Text(chat.title),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy HH:mm').format(chat.lastModified),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: chat.id == _currentChatId,
                    selectedTileColor: Colors.grey[200],
                    onTap: () {
                      setState(() {
                        _currentChatId = chat.id;
                        _loadMessages(chat.id);
                      });
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Chat'),
                            content: const Text('Are you sure you want to delete this chat?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteChat(chat.id);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Crop Advisor AI'),
        elevation: 0,
        /*flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.blueAccent],
            ),
          ),
        ),*/
        actions: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showLanguageDialog,
                  icon: const Icon(Icons.language_outlined),
                  tooltip: 'Change Language',
                ),
                Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      icon: const Icon(Icons.history),
                      tooltip: 'Chat History',
                    );
                  },
                ),
                Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      onPressed: () =>  Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>  CropListScreen(
                              userId: widget.userId, controllerId: widget.controllerId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.agriculture_rounded),
                      tooltip: 'Crop Advisory',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Start chatting with your Crop Advisor!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final message = _messages[index];
                return GestureDetector(
                  onLongPress: message.role == 'user' && !message.isImage
                      ? () => _editMessage(message)
                      : null,
                  child: MessageBubble(
                    key: ValueKey(message.timestamp.toString()),
                    message: message,
                  ),
                );
              },
            ),
          ),
          ChatInputField(
            controller: _controller,
            onSend: _sendMessage,
            onPickImage: _pickImage,
            onStartListening: (){},
            isListening: _isListening,
            selectedImage: _selectedImage,
            isEditing: _editingMessage != null,
            onCancelEdit: () {
              setState(() {
                _editingMessage = null;
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(ImageSource) onPickImage;
  final VoidCallback onStartListening;
  final bool isListening;
  final File? selectedImage;
  final bool isEditing;
  final VoidCallback onCancelEdit;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    required this.onStartListening,
    required this.isListening,
    this.selectedImage,
    required this.isEditing,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Image.file(
                    selectedImage!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        (context as Element)
                            .findAncestorStateOfType<_AIChatScreenState>()
                            ?.setState(() {
                          (context)
                              .findAncestorStateOfType<_AIChatScreenState>()
                              ?._selectedImage = null;
                          (context)
                              .findAncestorStateOfType<_AIChatScreenState>()
                              ?._imageSource = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.blue),
                onPressed: () => _showAttachmentOptions(context),
                tooltip: 'Attach',
              ),
              /*IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.red : Colors.blue,
                ),
                onPressed: onStartListening,
                tooltip: isListening ? 'Stop Recording' : 'Record Voice',
              ),*/
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: isEditing ? 'Edit message...' : 'Type a message...',
                    border: InputBorder.none,
                    suffixIcon: isEditing
                        ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: onCancelEdit,
                    )
                        : null,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.save : Icons.send,
                  color: Colors.blue,
                ),
                onPressed: onSend,
                tooltip: isEditing ? 'Save Edit' : 'Send',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Colors.blue),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              onPickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              onPickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              isUser ? 'You' : 'AI Assistant',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser
                        ? [Theme.of(context).primaryColor, Colors.blueAccent]
                        : [Colors.grey[200]!, Colors.grey[300]!],
                  ),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: Radius.circular(isUser ? 20 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.isImage)
                      GestureDetector(
                        onTap: () => _showFullImage(context, widget.message.content),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(widget.message.content),
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    if (widget.message.text != null || !widget.message.isImage)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: isUser
                            ? Text(
                          widget.message.isImage
                              ? widget.message.text!
                              : widget.message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                            :

                        const Text(''),),
                    if (widget.message.source != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Source: ${widget.message.source}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('h:mm a').format(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}