import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/views/pages/search_results.dart';
import 'package:fashionfrontend/views/widgets/second_header.dart';
import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/app_colors.dart';

class SwipeableCardController {
  VoidCallback? undo;
  VoidCallback? filter;
}

class HomePage extends StatelessWidget {
  static final GlobalKey<SwipeableCardState> _swipeableCardKey = GlobalKey();
  static final _cardController = SwipeableCardController();

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PageStorageKey('home'),
      body: Column(
        children: [
          SecondHeader(
            onUndo: () {
              _cardController.undo?.call();
            },
            onFilter: () {
              _cardController.filter?.call();
            },
          ),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.searchQuery.isNotEmpty) {
                  return SearchResultsPage();
                }
                return Container(
                  color: AppColors.surface,
                  child: SwipeableCard(
                    key: _swipeableCardKey,
                    controller: _cardController,
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