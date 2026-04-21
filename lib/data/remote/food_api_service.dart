import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item_model.dart';

class FoodApiService {
  Future<List<FoodItemModel>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=20',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data makanan');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>? ?? []);

    return products
        .map((e) => FoodItemModel.fromOpenFoodFacts(e as Map<String, dynamic>))
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }
}