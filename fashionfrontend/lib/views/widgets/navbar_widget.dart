import 'package:fashionfrontend/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class NavbarWidget extends StatelessWidget {
  NavbarWidget({super.key});

  int currentPageIndex = 0;
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: const Color.fromARGB(255, 4, 62, 104), //Blue Color
    primary: const Color.fromARGB(255, 255, 255, 255), //Cream Color
    onPrimary: Color.fromARGB(255, 167, 184, 196),
    secondary: const Color.fromARGB(255, 4, 62, 104), //Blue Color
    tertiary: const Color.fromARGB(255, 207, 36, 36), //Red Color
    surface: const Color.fromARGB(255, 255, 255, 255), //Background Color
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Container(
          height: 100,
          color: colorScheme.surface,
          child: NavigationBar(
            backgroundColor: colorScheme.primary,
            onDestinationSelected: (int index) {
              selectedPageNotifier.value = index;
            },
            indicatorColor: colorScheme.secondary,
            selectedIndex: selectedPage,
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.onPrimary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: 'Home',
              ),
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.onPrimary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: 'Liked',
              ),
              //!THIS IS A COMING FEATURE, NOT IN VERSION 1.0
              /* NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Bookmark.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Bookmark.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.onPrimary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: '',
              ), */
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(colorScheme.onPrimary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
  Size get preferredSize => Size.fromHeight(100);
}
