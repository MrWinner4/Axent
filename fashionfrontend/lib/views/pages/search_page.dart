import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashionfrontend/app_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  List<String> _suggestions = [];
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

  Future<List<String>> fetchSuggestions(String query) async {
    final Dio dio = Dio();
    final url = Uri.parse('$baseURL/products/search?q=$query');
    final response = await dio.getUri(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.data);
      return data.map<String>((item) => item['title'] as String).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _suggestions = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            _fetchSuggestions(query);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
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
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        // Handle suggestion selection
                        _textController.text = suggestion;
                        // Close keyboard
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        _focusNode.unfocus();
                        // Navigate back with selected item
                        Navigator.pop(context, suggestion);
                      },
                    );
                  },
                ),
    );
  }
} 