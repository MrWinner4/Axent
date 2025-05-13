import 'dart:async';

import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String likedProductsBaseUrl = 'https://axentbackend.onrender.com/likedProducts';

class HeartPage extends StatefulWidget {
  const HeartPage({super.key});
  
  @override
  HeartPageState createState() => HeartPageState();
}

class HeartPageState extends State<HeartPage>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  void refreshLikedProducts() {
    setState(() {
      _isLoading = true;
    });
    fetchLikedProducts();
  }

  @override
  void initState() {
    super.initState();
    print("hi");
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
        '$likedProductsBaseUrl/liked_products/',
        options: Options(
          headers: {
            'Authorization':
                'Bearer $idToken', // Pass the token in Authorization header
          },
        ),
      );

      // Update the products list
      if (mounted) {
        _productsNotifier.value = response.data;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching liked products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: ValueListenableBuilder<List<dynamic>>(
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

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await createWardrobe(context, mounted);
              },
              backgroundColor: Color.fromARGB(255, 4, 62, 104),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Your Wardrobes",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    LikedProductsSection(
                        Products: recentProducts.cast<Map<String, dynamic>>()),
                    SizedBox(
                      height: 40,
                    ),
                    Wardrobe(products: products),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> createWardrobe(context, mounted) async {
  try {
    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Creating wardrobe...'),
        ],
      ),
    ),
  );
  final String baseURL = ('https://axentbackend.onrender.com/wardrobes/');
  final Dio dio = Dio();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not authenticated");
  }

  final token = await user.getIdToken();


  final response = await dio.post(baseURL,
      data: {'name': 'New Wardrobe'},
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }));

  if (response.statusCode == 201) {
    print("wardrobe successful");
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wardrobe created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Failed to create wardrobe');
    }
  }
  } catch (e) {
    print("error creating wardrobe: $e");
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create wardrobe: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class Wardrobe extends StatelessWidget {
  final products;
  const Wardrobe({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
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
              color: Color.fromARGB(64, 6, 104, 173),
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with shoe images
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wardrobe.name',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LikedProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> Products;
  const LikedProductsSection({super.key, required this.Products});

  @override
  Widget build(BuildContext context) {
    if (Products.isEmpty) {
      return Container();
    }

    // Reverse the list so the most recent shoe appears first
    final reversedProducts = List.from(Products.reversed);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
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
              color: Color.fromARGB(64, 6, 104, 173),
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
                reversedProducts.length,
                (index) {
                  final shoe = reversedProducts[index];
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
                RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      children: [
                        TextSpan(text: 'Liked Products'),
                      ],
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
