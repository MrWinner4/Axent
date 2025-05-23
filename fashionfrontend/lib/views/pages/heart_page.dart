import 'dart:async';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String likedProductsBaseUrl =
    'https://axentbackend.onrender.com/preferences';
const String wardrobesBaseUrl = 'https://axentbackend.onrender.com/wardrobes';

class HeartPage extends StatefulWidget {
  const HeartPage({super.key});

  @override
  HeartPageState createState() => HeartPageState();
}

class HeartPageState extends State<HeartPage>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Wardrobe>> _wardrobesNotifier = ValueNotifier([]);
  bool _isLoading = true;
  bool _isWardrobesLoading = true;

  @override
  bool get wantKeepAlive => true;

  void refreshLikedProducts() {
    setState(() {
      _isLoading = true;
    });
    fetchLikedProducts();
  }

  void refreshWardrobes() {
    setState(() {
      _isWardrobesLoading = true;
    });
    fetchWardrobes();
  }

  @override
  void initState() {
    super.initState();
    fetchLikedProducts();
    fetchWardrobes();
  }

  @override
  void dispose() {
    _productsNotifier.dispose();
    _wardrobesNotifier.dispose();
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

  Future<void> fetchWardrobes() async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;

      // Get user ID from token
      final decodedToken =
          await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      final userId = decodedToken.claims?['user_id'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      final response = await Dio().get(
        '$wardrobesBaseUrl/user/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
        queryParameters: {
          'user_id': userId,
        },
      );

      if (mounted && response.data != null) {
        _wardrobesNotifier.value =
            response.data.map((json) => Wardrobe.fromJson(json)).toList();
        setState(() {
          _isWardrobesLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching wardrobes: $e');
      if (mounted) {
        setState(() {
          _isWardrobesLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wardrobes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> createWardrobe(BuildContext context, bool mounted) async {
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

      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().post(
        '$wardrobesBaseUrl/',
        data: {'name': 'New Wardrobe'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wardrobe created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        refreshWardrobes(); // Refresh the wardrobes list
      }
    } catch (e) {
      print('Error creating wardrobe: $e');
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

  Future<void> deleteWardrobe(String wardrobeId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().delete(
        '$wardrobesBaseUrl/$wardrobeId/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error deleting wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addToWardrobe(String wardrobeId, String productId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().post(
        '$wardrobesBaseUrl/$wardrobeId/add_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error adding to wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> removeFromWardrobe(String wardrobeId, String productId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().post(
        '$wardrobesBaseUrl/$wardrobeId/remove_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error removing from wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ColorScheme.of(context).surfaceBright,
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
              backgroundColor: ColorScheme.of(context).primary,
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
                    ValueListenableBuilder<List<Wardrobe>>(
                      valueListenable: _wardrobesNotifier,
                      builder: (context, wardrobes, _) {
                        if (_isWardrobesLoading) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (wardrobes.isEmpty) {
                          return Center(child: Text("No wardrobes."));
                        }

                        return Column(
                          children: wardrobes
                              .map((wardrobe) =>
                                  WardrobeWidget(wardrobe: wardrobe))
                              .toList(),
                        );
                      },
                    ),
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

class WardrobeWidget extends StatelessWidget {
  final Wardrobe wardrobe;
  const WardrobeWidget({super.key, required this.wardrobe});

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
              color: Colors.black.withAlpha(64),
              offset: Offset(0, 0),
              blurRadius: 20,
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
                  wardrobe.name,
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
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(64),
              offset: Offset(0, 0),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                    children: [
                      TextSpan(text: '❤ ', style: TextStyle(color: Colors.red)),
                      TextSpan(text: 'Liked Products'),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 28,
                    left: 24,
                    child: Container(
                      width: 70,
                      height: 60,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(64),
                                blurRadius: 10,
                                offset: Offset(4, 4))
                          ]),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 20,
                    child: Container(
                      width: 70,
                      height: 60,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(64),
                                blurRadius: 10,
                                offset: Offset(4, 4))
                          ]),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(64),
                            blurRadius: 10,
                            offset: Offset(4, 4),
                          )
                        ]),
                    child: Image.network(
                      reversedProducts[0]['images']?.first['image_url'] ??
                          'assets/images/default_shoe.jpg',
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
            ),
            Text("102 saved shoes", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }
}
