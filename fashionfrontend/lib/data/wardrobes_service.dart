import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';

class WardrobesService {
  static final WardrobesService _instance = WardrobesService._internal();
  factory WardrobesService() => _instance;
  WardrobesService._internal();

  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://axentbackend.onrender.com/wardrobes';

  static Future<String> _getIdToken() async {
    return (await FirebaseAuth.instance.currentUser!.getIdToken())!;
  }

  static Future<String> _getUserId() async {
    final decodedToken = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    final userId = decodedToken.claims?['user_id'];
    if (userId == null) {
      throw Exception('User ID not found in token');
    }
    return userId;
  }

  // Fetch all wardrobes for the current user
  static Future<List<Wardrobe>> fetchWardrobes() async {
    try {
      final idToken = await _getIdToken();
      final userId = await _getUserId();
      
      print('Fetching wardrobes for user: $userId');
      final response = await _dio.get(
        '$_baseUrl/user/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
        queryParameters: {'firebase_uid': userId},
      );

      print('Wardrobes response status: ${response.statusCode}');
      print('Wardrobes response data: ${response.data}');

      if (response.data == null) return [];
      
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Wardrobe.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching wardrobes: $e');
      return [];
    }
  }

  // Create a new wardrobe
  static Future<void> createWardrobe(String name) async {
    try {
      final idToken = await _getIdToken();
      final userId = await _getUserId();
      
      print('Creating wardrobe: $name for user: $userId');
      final response = await _dio.post(
        '$_baseUrl/',
        data: {'name': name, 'user': userId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Create wardrobe response status: ${response.statusCode}');
      print('Create wardrobe response data: ${response.data}');
    } catch (e) {
      print('Error creating wardrobe: $e');
      rethrow;
    }
  }

  // Delete a wardrobe
  static Future<void> deleteWardrobe(String wardrobeId) async {
    try {
      final idToken = await _getIdToken();
      await _dio.delete(
        '$_baseUrl/$wardrobeId/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
    } catch (e) {
      print('Error deleting wardrobe: $e');
      rethrow;
    }
  }

  // Add a product to a wardrobe
  static Future<void> addToWardrobe(String wardrobeId, String productId) async {
    try {
      final idToken = await _getIdToken();
      print('Adding product $productId to wardrobe $wardrobeId');
      
      final response = await _dio.post(
        '$_baseUrl/$wardrobeId/add_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 600, // Allow 500 errors to be handled
        ),
      );
      
      print('Add to wardrobe response status: ${response.statusCode}');
      print('Add to wardrobe response data: ${response.data}');
      
      if (response.statusCode! >= 400) {
        throw Exception('Server error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error adding product to wardrobe: $e');
      rethrow;
    }
  }

  // Remove a product from a wardrobe
  static Future<void> removeFromWardrobe(String wardrobeId, String productId) async {
    try {
      final idToken = await _getIdToken();
      await _dio.post(
        '$_baseUrl/$wardrobeId/remove_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
    } catch (e) {
      print('Error removing product from wardrobe: $e');
      rethrow;
    }
  }

  // Get products in a wardrobe
  static Future<List<CardData>> getWardrobeProducts(String wardrobeId) async {
    try {
      final idToken = await _getIdToken();
      
      print('Fetching wardrobe details for: $wardrobeId');
      
      // Fetch wardrobe details
      final wardrobeResponse = await _dio.get(
        '$_baseUrl/$wardrobeId/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Wardrobe response: ${wardrobeResponse.data}');

      final productIds = wardrobeResponse.data['product_ids'] != null
          ? (wardrobeResponse.data['product_ids'] as List<dynamic>).cast<String>()
          : [];

      print('Product IDs found: $productIds');

      // Fetch each product individually
      final products = await Future.wait(
        productIds.map((productId) async {
          try {
            print('Fetching product: $productId');
            final productResponse = await _dio.get(
              'https://axentbackend.onrender.com/preferences/product_detail/$productId/',
              options: Options(
                headers: {'Authorization': 'Bearer $idToken'},
                followRedirects: true,
                validateStatus: (status) => status! < 500,
              ),
            );
            print('Product $productId response: ${productResponse.data}');
            return CardData.fromJson(productResponse.data);
          } catch (e) {
            print('Error fetching product $productId: $e');
            return null;
          }
        }).toList(),
      );

      final validProducts = products.where((product) => product != null).cast<CardData>().toList();
      print('Valid products found: ${validProducts.length}');
      return validProducts;
    } catch (e) {
      print('Error fetching wardrobe products: $e');
      return [];
    }
  }

  // Check if a product is in a wardrobe
  static Future<bool> isProductInWardrobe(String wardrobeId, String productId) async {
    try {
      final products = await getWardrobeProducts(wardrobeId);
      return products.any((product) => product.id == productId);
    } catch (e) {
      return false;
    }
  }

  // Get all wardrobes containing a specific product
  static Future<List<Wardrobe>> getWardrobesContainingProduct(String productId) async {
    try {
      final allWardrobes = await fetchWardrobes();
      final containingWardrobes = <Wardrobe>[];
      
      for (final wardrobe in allWardrobes) {
        final isContaining = await isProductInWardrobe(wardrobe.id, productId);
        if (isContaining) {
          containingWardrobes.add(wardrobe);
        }
      }
      
      return containingWardrobes;
    } catch (e) {
      return [];
    }
  }
} 