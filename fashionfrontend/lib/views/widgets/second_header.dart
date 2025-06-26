import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'custom_search_bar.dart';

class SecondHeader extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onFilter;
  const SecondHeader({super.key, this.onUndo, this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 251, 252, 254),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Undo button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                  BoxShadow(
                      color: Color.fromARGB(64, 0, 0, 0),
                      spreadRadius: 2,
                      blurStyle: BlurStyle.outer,
                      blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: const Icon(Icons.undo_rounded),
                onPressed: () async {
                  try {
                    if (onUndo != null) {
                      onUndo!();
                    }
                  } catch (e) {
                    print('Error during undo: $e');
                  }
                },
              ),
            ),
            // Search bar
            SizedBox(
                height: 48,
                width: MediaQuery.of(context).size.width * .6,
              child: CustomSearchBar(),
              
            ),
            // Filter button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color.fromARGB(64, 0, 0, 0),
                      spreadRadius: 2,
                      blurStyle: BlurStyle.outer,
                      blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () async {
                  try {
                    if(onFilter != null) {
                      onFilter!();
                    }
                  } catch (e) {
                    print('Error during filter: $e');
                  }
                },
                /* shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.black12),
                ), */
              ),
            ),
          ],
        ),
      ),
    );
  }
}
