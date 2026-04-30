import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final prompt = '''
Generate 4 helpful and empowering articles or blogs about "Online Abuse" for a women's safety app.
Return ONLY a valid JSON object with a "blogs" array. Do not return markdown formatting like ```json.
Each object in the array should have these exact string keys:
- "title": A catchy, relevant title.
- "description": A 2-sentence summary.
- "content": A comprehensive, empowering 3-paragraph article/blog post providing actionable advice and support. Use plain text.
- "type": Either "Blog" or "Article".
- "category": A short category name (e.g. "Safety", "Legal", "Mental Health").
- "date": A date string like "Oct 12, 2023".
''';

  try {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyD5QwUhjz_b1Wm65O9qPDdU-vYuCW0lS-4'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.7}
      }),
    );

    print('Status: \${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      print('Raw text: \$text');
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final result = jsonDecode(cleanText);
      print('Parsed successfully. Found \${result['blogs']?.length} blogs.');
      print('First blog content: \${result['blogs'][0]['content'] != null ? 'Present' : 'Null'}');
    } else {
      print(response.body);
    }
  } catch (e) {
    print('Error: \$e');
  }
}
