import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item_model.dart';

class FoodApiService {
  static const String _apiKey = 'b4C8zTBXciaJipPjCQyfATJ3LpZnK6tjP7ZFIead';

  Future<List<FoodItemModel>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$_apiKey',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'pageSize': 20,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data makanan dari USDA');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = (data['foods'] as List<dynamic>? ?? []);

    return foods
        .map((e) => FoodItemModel.fromUsda(e as Map<String, dynamic>))
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }
}