import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/views/pages/search_results.dart';
import 'package:fashionfrontend/views/widgets/second_header.dart';
import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SecondHeader(),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.searchQuery.isNotEmpty) {
                  return SearchResultsPage();
                }
                return Center(
                  child: Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    child: SwipeableCard(user: user),
                  ),
                );
              },
            ),
          )
        ],
      )
    );
  }
}