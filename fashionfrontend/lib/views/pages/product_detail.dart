import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Use the same base URL as before.
const String apiBaseUrl = 'http://127.0.0.1:8000/api';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Future<Map<String, dynamic>>? productDetail;

  @override
  void initState() {
    super.initState();
    productDetail = fetchProductDetail();
  }

  Future<Map<String, dynamic>> fetchProductDetail() async {
    try {
      final response = await Dio().get('$apiBaseUrl/product_detail/${widget.productId}/');
      print('$apiBaseUrl/product_detail/${widget.productId}/');
      return response.data; // Expect a JSON object
    } catch (e) {
      print('Error fetching product detail: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Detail'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: productDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Product details not available."));
          }
          final product = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display product image
                Center(
                  child: Image.network(product['image'], height: 250),
                ),
                SizedBox(height: 20),
                Text(product['name'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('\$${product['price'].toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, color: Colors.green)),
                SizedBox(height: 20),
                Text(product['description'] ?? 'No description available.',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 30),
                // "Buy" button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add your buy action / navigation to checkout here.
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Buy functionality not implemented.")));
                    },
                    child: Text("Buy Now"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
