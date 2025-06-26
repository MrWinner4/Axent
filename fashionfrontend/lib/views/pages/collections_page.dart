import 'package:fashionfrontend/views/widgets/collection_cell.dart';
import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';


class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override //!THIS IS A COMING FEATURE, NOT IN VERSION 1.0
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 25.0,
        children: [
          Text(
            'Liked Items',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 4, 62, 104)
            ),
          ),
          Center(
            child: Column(
              spacing: 25.0, 
              children: [
              for (int i = 0; i < 10; i++) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25.0,
                children: [
                  CollectionCell(),
                ],
              ),
            ]),
          ),
        ],
      ),
    ));
  }
}