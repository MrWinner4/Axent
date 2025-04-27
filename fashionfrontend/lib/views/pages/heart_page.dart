import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String apiBaseUrl = 'https://axentbackend.onrender.com/api';

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

