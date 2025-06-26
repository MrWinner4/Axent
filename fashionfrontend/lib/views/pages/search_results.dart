import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/views/pages/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/app_colors.dart';

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: searchProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchProvider.searchResults.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: searchProvider.searchResults.length,
                itemBuilder: (context, index) {
                  final product = searchProvider.searchResults[index];
                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        product.images.first,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(product.title),
                      subtitle: Text(product.brand),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(product: 
                            {//DO later
                        },),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}