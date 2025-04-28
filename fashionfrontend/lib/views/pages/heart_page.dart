import 'dart:async';

import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String apiBaseUrl = 'https://axentbackend.onrender.com/api';

class HeartPage extends StatefulWidget {
  @override
  HeartPageState createState() => HeartPageState();
}

class HeartPageState extends State<HeartPage> {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  bool _isLoading = true;

  void refreshLikedProducts() {
    setState(() {
      _isLoading = true;
    });
    fetchLikedProducts();
  }

  @override
  void initState() {
    super.initState();
    fetchLikedProducts();
  }

  @override
  void dispose() {
    _productsNotifier.dispose();
    super.dispose();
  }

  Future<void> fetchLikedProducts() async {
    try {
      // Get the Firebase ID token
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;

      // Send the ID token in the Authorization header
      final response = await Dio().get(
        '$apiBaseUrl/liked_products/',
        options: Options(
          headers: {
            'Authorization':
                'Bearer $idToken', // Pass the token in Authorization header
          },
        ),
      );

      // Update the products list
      _productsNotifier.value = response.data;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching liked products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _productsNotifier,
      builder: (context, products, _) {
        if (_isLoading) {
          print('Loading...');
          return Center(child: CircularProgressIndicator());
        }
        if (products.isEmpty) {
          return Center(child: Text("No liked products."));
        }

        // Take the last 3 items (most recent)
        final recentProducts = products.length >= 3
            ? products.sublist(products.length - 3)
            : products;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreviewSection(
                    shoes: recentProducts.cast<Map<String, dynamic>>()),
                SizedBox(
                  height: 40,
                ),
                Center(
                  child: Text(
                    "more coming soon...",
                    style: TextStyle(color: Color.fromARGB(255, 124, 149, 167)),
                  ),
                )
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
class PreviewSection extends StatelessWidget {
  final List<Map<String, dynamic>> shoes;
  const PreviewSection({required this.shoes});

  @override
  Widget build(BuildContext context) {
    print('Building PreviewSection with ${shoes.length} shoes');

    if (shoes.isEmpty) {
      return Container();
    }

    // Reverse the list so the most recent shoe appears first
    final reversedShoes = List.from(shoes.reversed);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder
          (pageBuilder: (context, animation, secondaryAnimation) =>
                LikedProductsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 6, 104, 173),
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with shoe images
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                reversedShoes.length,
                (index) {
                  final shoe = reversedShoes[index];
                  final imageUrl = shoe['images']?.first['image_url'] ??
                      'assets/images/default_shoe.jpg';
                  return Flexible(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default_shoe.jpg',
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Liked shoes',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "see more...",
                  style: TextStyle(color: Color.fromARGB(255, 124, 149, 167)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
