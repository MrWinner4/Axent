import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/data/recombee_service.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';

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
                  child: Text(
                    'Start typing to search...',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return ListTile(
                      leading: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image);
                              },
                            )
                          : const Icon(Icons.image),
                      title: Text(product.title),
                      subtitle: Text(product.brand),
                      trailing: Text(product.formattedPrice),
                      onTap: () {
                        // Handle product selection
                        _textController.text = product.title;
                        // Close keyboard
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        _focusNode.unfocus();
                        // Navigate back with selected product
                        Navigator.pop(context, product);
                      },
                    );
                  },
                ),
    );
  }
} 