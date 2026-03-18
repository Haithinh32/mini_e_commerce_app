import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://fakestoreapi.com';

  static Future<List<Product>> getProducts({int limit = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/products?limit=$limit'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/products/categories'));
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
