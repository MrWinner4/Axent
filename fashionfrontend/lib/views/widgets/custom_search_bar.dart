import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/views/pages/search_page.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to dedicated search page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchPage(),
          ),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), // Rounded rectangle
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(64),
              spreadRadius: 2,
              blurStyle: BlurStyle.outer,
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Find your fashion...',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: AppColors.onSurface,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
