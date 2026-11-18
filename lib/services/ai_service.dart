import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  final String _apiKey = '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';

  Future<String> sendTextToAI(String text, String selectedLanguage) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [{
          "role": "system",
          "content": "You are an expert crop advisor. Always respond in $selectedLanguage. "
              "Analyze the uploaded crop image and provide a diagnosis of any visible crop issues."
        },
        {'role': 'user', 'content': text}],
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('AI request failed: ${response.statusCode}');
    }
  }
}
