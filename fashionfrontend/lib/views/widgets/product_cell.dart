import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class ProductCell extends StatelessWidget {

  final double size;

  const ProductCell({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("bruh");
      },
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 252, 246, 237),
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.all(width: 2)
        ),
        //252 246 237
      ),
    );
  }
}