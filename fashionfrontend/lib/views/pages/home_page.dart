import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/views/pages/search_results.dart';
import 'package:fashionfrontend/views/widgets/second_header.dart';
import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static final GlobalKey<SwipeableCardState> _swipeableCardKey = GlobalKey();

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SecondHeader(
            onUndo: () {
              final swipeableCardState = _swipeableCardKey.currentState;
              if (swipeableCardState != null) {
                print("broski");
                swipeableCardState.undo();
              } 
            },
          ),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.searchQuery.isNotEmpty) {
                  return SearchResultsPage();
                }
                return Container(
                  color: const Color.fromARGB(255, 251, 252, 254),
                  child: SwipeableCard(
                    key: _swipeableCardKey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}