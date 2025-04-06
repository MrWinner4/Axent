import 'package:fashionfrontend/views/widgets/product_cell.dart';
import 'package:flutter/material.dart';

class LikedPage extends StatefulWidget {
  const LikedPage({super.key});

  @override
  State<LikedPage> createState() => LikedPageState();
}

class LikedPageState extends State<LikedPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final CELLSIZE = .4 * screenWidth;
    final SPACINGSIZE = screenWidth / 20;
    final MAJORSPACINGSIZE = screenWidth / 10;
    final BUTTONHEIGHT = 40.0;
    final BUTTONWIDTH = (CELLSIZE) - 5;
    final double FONTSIZE = screenWidth * 0.024; // tweak this ratio as needed
    final double ASPECTRATIO = (175 / 30);
    print(CELLSIZE);
    print("cell");
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: MAJORSPACINGSIZE,
          children: [
            Text(
              'Liked Items',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 4, 62, 104)),
            ),
            Row(
              spacing: SPACINGSIZE,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: BUTTONWIDTH,
                  child: AspectRatio(
                    aspectRatio: ASPECTRATIO,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDF8F2),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                            color: Color(0xFF043E68),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sort By',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: FONTSIZE,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF043E68),
                            ),
                          ),
                          Text(
                            'Most Recent',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: FONTSIZE,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF043E68),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.black, size: FONTSIZE + 4),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: BUTTONWIDTH,
                  child: AspectRatio(
                    aspectRatio: ASPECTRATIO,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDF8F2),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                            color: Color(0xFF043E68),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: FONTSIZE,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF043E68),
                            ),
                          ),
                          Text(
                            'All Products',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: FONTSIZE,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF043E68),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.black, size: FONTSIZE + 4),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            Center(
              child: Column(spacing: SPACINGSIZE, children: [
                for (int i = 0; i < 10; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: SPACINGSIZE,
                    children: [
                      ProductCell(size: CELLSIZE),
                      ProductCell(size: CELLSIZE),
                    ],
                  ),
              ]),
            ),
          ],
        ),
      ),
    ));
  }
}
