import 'package:flutter/material.dart';
import 'custom_search_bar.dart';

class SecondHeader extends StatelessWidget {
  const SecondHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
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
                      offset: Offset(0, 0)),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: const Icon(Icons.undo_rounded),
                onPressed: () {
                  
                },
                /* shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.black12),
                ), */
              ),
            ),
            // Search bar
            SizedBox(
                height: 48,
                width: MediaQuery.of(context).size.width * .6,
                child: CustomSearchBar()),
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
                      offset: Offset(0, 0)),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () {},
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
