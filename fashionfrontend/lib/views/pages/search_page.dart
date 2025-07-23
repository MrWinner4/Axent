import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/data/recombee_service.dart';
import 'package:fashionfrontend/data/product_service.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/views/pages/product_info_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  List<CardData> _searchResults = [];
  bool _loading = false;
  String _lastQuery = '';
  final String baseURL = 'https://axentbackend.onrender.com/';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    
    // Auto-focus the search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSearchResults(String query, String userId) async {
    if (query.isEmpty || query == _lastQuery) return;
    setState(() {
      _loading = true;
      _lastQuery = query;
    });
    try {
      final results = await RecombeeService.searchProducts(query, userId: userId);
      if (mounted && query == _lastQuery) {
        setState(() {
          _searchResults = results;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Close keyboard and navigate back
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            _focusNode.unfocus();
            Navigator.pop(context);
          },
        ),
        title: TextField(
          controller: _textController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Find your fashion...',
            hintStyle: TextStyle(color: AppColors.onSurface),
            border: InputBorder.none,
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _textController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            if(userId != null) {
              _fetchSearchResults(query, userId);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No results found.',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different keyword or check your spelling.',
                        style: TextStyle(
                          color: AppColors.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        
                        try {
                          // Fetch full product details from Django backend
                          final fullProduct = await ProductService.getProductById(product.id);
                          
                          // Hide loading indicator
                          Navigator.pop(context);
                          
                          if (fullProduct != null) {
                            // Navigate to product detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductInfoPage(product: fullProduct),
                              ),
                            );
                          } else {
                            // Show error if product not found
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product details not found'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          // Hide loading indicator
                          Navigator.pop(context);
                          
                          // Show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error loading product: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.images.isNotEmpty
                                    ? Image.network(
                                        product.images.first,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              width: 72,
                                              height: 72,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 32),
                                            ),
                                      )
                                    : Container(
                                        width: 72,
                                        height: 72,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 32),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.brand,
                                      style: TextStyle(
                                        color: AppColors.onSurface.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.formattedPrice,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Optional: Add a favorite/like button here
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