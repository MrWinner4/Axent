import 'package:dio/dio.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/config/recombee_config.dart';

class RecombeeService {
  static final RecombeeService _instance = RecombeeService._internal();
  factory RecombeeService() => _instance;
  RecombeeService._internal();

  static final Dio _dio = Dio();
  static final RESULTCOUNT = 10;
  static final String publicToken = 'rRwGfBTEEFjAAsdQJgNE7DeZ0MofM1hfBwbS7B5xD6bA3VTxXptecN71Cxro8nw2';

  // Search products using Recombee
  static Future<List<CardData>> searchProducts(String query, {
    int count = 10,
    required String userId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var includedProperties = ["brand", "title", "retailprice", "image"];

      final response = await _dio.get(
        buildRecombeeUrl(query, userId, RESULTCOUNT),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('🔍 Recombee response status: ${response.statusCode}');
      print('🔍 Recombee response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['recomms'] ?? [];
        print('🔍 Found ${results.length} results');
        
        // Debug: Show detailed info about each result
        for (int i = 0; i < results.length; i++) {
          final item = results[i];
          final properties = item['values'] ?? {};
          print('🔍 Result $i:');
          print('  - ID: ${item['id']}');
          print('  - Title: ${properties['title']}');
          print('  - Brand: ${properties['brand']}');
          print('  - Price: ${properties['retailprice']}');
          print('  - Image URL: ${properties['image']}');
          print('  ---');
        }
        return results.map<CardData>((item) {
          final properties = item['values'] ?? {};
          return CardData(
            id: item['id'] ?? '',
            title: properties['title'] ?? '',
            brand: properties['brand'] ?? '',
            description: '',
            upcoming: false,
            colorway: [],
            trait: false,
            retailPrice: (properties['retailprice'] ?? 0).toDouble(),
            sizeLowestAsks: {},
            images: properties['image'] != null ? [properties['image']] : ['assets/images/Shoes1.jpg'],
            likedAt: DateTime.now(),
            images360: ['assets/images/Shoes1.jpg'],
          );
        }).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching products with Recombee: $e');
      return [];
    }
  }

  // Send user interaction to Recombee (for learning)
  /* static Future<void> sendInteraction({
    required String userId,
    required String itemId,
    required String interactionType, // 'view', 'like', 'dislike', etc.
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      
      final Map<String, dynamic> requestData = {
        'user_id': userId,
        'item_id': itemId,
        'interaction_type': interactionType,
      };

      if (additionalData != null) {
        requestData.addAll(additionalData);
      }

      await _dio.post(
        buildRecombeeUrl(query, userId),
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $publicToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
    } catch (e) {
      print('Error sending interaction to Recombee: $e');
    }
  } */
} 