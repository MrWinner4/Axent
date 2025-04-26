import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String apiBaseUrl = 'http://127.0.0.1:8000/api';

class LikedPage extends StatefulWidget {
  @override
  _LikedPageState createState() => _LikedPageState();
}

class _LikedPageState extends State<LikedPage> {
  Future<List<dynamic>>? likedProducts;

  @override
  void initState() {
    super.initState();
    likedProducts = fetchLikedProducts();
  }

  Future<List<dynamic>> fetchLikedProducts() async {
    try {
      // Get the Firebase ID token
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;

      // Send the ID token in the Authorization header
      final response = await Dio().get(
        '$apiBaseUrl/liked_products/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken', // Pass the token in Authorization header
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error fetching liked products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: likedProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading products"));
        }
        List<dynamic> products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text("No liked products."));
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: 'Liked Shoes'),
                SizedBox(height: 20),
                Stack(
                  children: List.generate(
                    products.length > 3 ? 3 : products.length,
                        (index) {
                      return Positioned(
                        top: index * 10.0,
                        left: index * 10.0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LikedDetailPage(products: products),
                              ),
                            );
                          },
                          child: ShoeCard(item: products[index]),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ShoeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ShoeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Image.network(item['image'], height: 80),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: TextStyle(fontSize: 20)),
                Text('\$${item['price'].toStringAsFixed(2)}'),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class LikedDetailPage extends StatelessWidget {
  final List<dynamic> products;
  const LikedDetailPage({required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Shoes'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(productId: product['id']),
                ),
              );
            },
            child: ShoeCard(item: product),
          );
        },
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final int productId;
  const ProductDetailPage({required this.productId});

  Future<Map<String, dynamic>> fetchProductDetails() async {
    try {
      final response = await Dio().get('$apiBaseUrl/liked_products/$productId/');
      return response.data;
    } catch (e) {
      print('Error fetching product detail: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF9F6),
      appBar: AppBar(
        title: Text('Product Detail'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProductDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Product not found'));
          }
          final product = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(product['image'], height: 200),
                ),
                SizedBox(height: 20),
                Text(product['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('\$${product['price'].toStringAsFixed(2)}', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                SizedBox(height: 20),
                Text(product['description'] ?? 'No description available.', style: TextStyle(fontSize: 16)),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // Add to cart functionality or buy now logic
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to cart!')));
                    },
                    child: Text('Buy Now', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
