import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class CollectionCell extends StatelessWidget {
  const CollectionCell({super.key});

  @override //! THIS IS A COMING FEATURE, NOT IN 1.0
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 350,
        height: 150,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 252, 246, 237),
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.all(width: 2)
        ),
        child: Column(
          children: [

          ]
        )
      ),
    );
  }
}