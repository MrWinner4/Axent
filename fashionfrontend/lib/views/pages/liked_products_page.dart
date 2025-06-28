import 'package:fashionfrontend/views/pages/product_info_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionfrontend/app_colors.dart';

class LikedProductsPage extends StatefulWidget {
  const LikedProductsPage({super.key});

  @override
  State<LikedProductsPage> createState() => _LikedProductsPageState();
}

class _LikedProductsPageState extends State<LikedProductsPage> {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  bool _isLoading = true;
  final preferencesBaseUrl = 'https://axentbackend.onrender.com/preferences';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Shoes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<dynamic>>(
        valueListenable: _productsNotifier,
        builder: (context, products, _) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return Center(
              child: Text(
                'No liked shoes yet',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            padding: EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[products.length - index - 1];
              final imageUrl = product['images']?.first['image_url'] ??
                  'assets/images/default_shoe.jpg';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductInfoPage(
                        product: product,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height *
                              .2, // 30% of screen height
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default_shoe.jpg',
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'] ?? 'Unknown Shoe',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),/* 
                            SizedBox(height: 12),
                            Text(
                              product['estimatedMarketValue'] != null
                                  ? '\$${product['estimatedMarketValue']}'
                                  : 'Price not available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ), */
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> fetchLikedProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      final response = await Dio().get(
        '$preferencesBaseUrl/liked_products/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

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
}
