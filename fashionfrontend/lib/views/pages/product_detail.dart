import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Use the same base URL as before.
const String apiBaseUrl = 'http://127.0.0.1:8000/api';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailPage({required this.product});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Detail'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CarouselSlider(
                options: CarouselOptions(
                    height: MediaQuery.of(context).size.height *
                        0.42, //42% of screen height
                    scrollDirection: Axis.horizontal,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.3,
                    initialPage: 0),
                items: product['images'] != null
                    ? product['images']
                        .map((image) {
                          return ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.42,
                              child: Image.network(
                                image['image_url'] ??
                                    'assets/images/default_shoe.jpg',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/default_shoe.jpg',
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          );
                        })
                        .toList()
                        .cast<Widget>()
                    : [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.42,
                            child: Image.asset(
                              'assets/images/default_shoe.jpg',
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.3,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ]),
          ),
          // The text overlay
          Container(
            height: MediaQuery.of(context).size.height * .58 - 88,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 254, 251, 247),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 10,
                  )
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title'] ?? 'Unknown Shoe',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Estimated Price: ${product['estimatedMarketValue'] != null ? '\$${product['estimatedMarketValue']}' : 'Not available'}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Model: ${product['silhouette'] != null ? '${product['silhouette']}' : 'Not available'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Retail Price: ${product['retailPrice'] != null ? '\$${product['retailPrice']}' : 'Not available'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Brand: ${product['brand'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          product['story'] ?? 'No description available',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color.fromARGB(255, 8, 141, 237),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showBuyOptions(context),
                      child: Text(
                        'Buy Now',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // "Buy" button
        ],
      ),
    );
  }

  void _showBuyOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buy Options',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    if (widget.product['urls']?['stockx'] != null)
                      ListTile(
                        leading: Icon(Icons.shopping_bag),
                        title: Text('StockX'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _launchUrl(
                              Uri.parse(widget.product['urls']['stockx']));
                          Navigator.pop(context);
                        },
                      ),
                    if (widget.product['urls']?['goat'] != null)
                      ListTile(
                        leading: Icon(Icons.shopping_bag),
                        title: Text('Goat'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _launchUrl(Uri.parse(widget.product['urls']['goat']));
                          Navigator.pop(context);
                        },
                      ),
                    if (widget.product['urls']?['flightclub'] != null)
                      ListTile(
                        leading: Icon(Icons.shopping_bag),
                        title: Text('Flight Club'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _launchUrl(
                              Uri.parse(widget.product['urls']['flightclub']));
                          Navigator.pop(context);
                        },
                      ),
                    if (widget.product['urls']?['stadiumgoods'] != null)
                      ListTile(
                        leading: Icon(Icons.shopping_bag),
                        title: Text('Stadium Goods'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _launchUrl(Uri.parse(
                              widget.product['urls']['stadiumgoods']));
                          Navigator.pop(context);
                        },
                      ),
                  ]));
        });
  }
  Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}
}
