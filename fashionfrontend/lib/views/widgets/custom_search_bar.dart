import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({super.key});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _suggestions = [];
  bool _loading = false;
  String _lastQuery = '';

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty || query == _lastQuery) return;
    setState(() {
      _loading = true;
      _lastQuery = query;
    });
    try {
      final results = await fetchSuggestions(query);
      if (mounted && query == _lastQuery) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: _searchController,
      builder: (context, controller) {
        return SearchBar(
          backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
          controller: controller,
          hintText: 'Find your fashion...',
          hintStyle: WidgetStateProperty.all<TextStyle>(
            const TextStyle(color: Colors.black),
          ),
          onTap: () {
            controller.openView();
          },
          onChanged: (query) {
            _fetchSuggestions(query);
            controller.openView();
          },
          trailing: const [Icon(Icons.search)],
        );
      },
      suggestionsBuilder: (context, controller) {
        if (_loading) {
          return [const Center(child: CircularProgressIndicator())];
        }
        return _suggestions.map((suggestion) {
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              controller.closeView(suggestion);
              debugPrint('Selected: $suggestion');
            },
          );
        }).toList();
      },
    );
  }

  final String baseURL = ('https://axentbackend.onrender.com/'); //

  Future<List<String>> fetchSuggestions(String query) async {
    print('hi');
    final Dio dio = Dio();
    final url = Uri.parse('$baseURL/products/search?q=$query');
    final response = await dio.getUri(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.data);
      print(response.data);
      return data.map<String>((item) => item['title'] as String).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }
}

// Remove _mockData; now using backend suggestions.
