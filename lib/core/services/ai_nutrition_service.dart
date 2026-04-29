import 'dart:convert';
import 'package:http/http.dart' as http;

class AiNutritionService {
  static final instance = AiNutritionService._();
  AiNutritionService._();

  static const _apiKey = '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'; // Ganti dengan API key OpenRouter
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.1-8b-instant';

  Future<String> _callApi(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Maaf, tidak ada respons.';
      }

      print('OpenRouter error ${response.statusCode}: ${response.body}');
      return 'Maaf, layanan AI sedang tidak tersedia.';
    } catch (e) {
      print('AI error: $e');
      return 'Maaf, terjadi kesalahan koneksi.';
    }
  }

  Future<String> askCoach({
    required String userMessage,
    required Map<String, dynamic> nutritionContext,
  }) async {
    final prompt = '''
Kamu adalah AI Nutrition Coach yang ahli dalam nutrisi dan fitness.
Berikut data nutrisi hari ini user:
- Kalori: ${nutritionContext['totalCalories']}/${nutritionContext['targetCalories']} kcal
- Protein: ${nutritionContext['totalProtein']}g
- Karbo: ${nutritionContext['totalCarbs']}g
- Lemak: ${nutritionContext['totalFat']}g
- Air: ${nutritionContext['totalWater']}/${nutritionContext['targetWater']}ml
- Goal: ${nutritionContext['goal']}

User bertanya: $userMessage

Berikan jawaban singkat, praktis, dan motivatif dalam Bahasa Indonesia.
''';

    return _callApi(prompt);
  }

  Future<String> getMealRecommendation({
    required Map<String, dynamic> context,
  }) async {
    final prompt = '''
Kamu adalah AI Nutrition Coach. User meminta rekomendasi makanan.
Data:
- Sisa kalori: ${context['remainingCalories']} kcal
- Goal: ${context['goal']}

Berikan 3 rekomendasi makanan dengan estimasi kalori dan alasan nutrisinya.
Format dengan bullet points. Bahasa Indonesia.
''';

    return _callApi(prompt);
  }
}