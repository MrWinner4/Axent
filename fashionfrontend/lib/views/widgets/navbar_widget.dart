import 'package:fashionfrontend/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fashionfrontend/app_colors.dart';

// ignore: must_be_immutable
class NavbarWidget extends StatelessWidget {
  NavbarWidget({super.key});

  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha(64), // Adjust opacity for intensity
                blurRadius: 10, // Adjust for spread
                offset: const Offset(0, 2), // Adjust for direction
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: AppColors.surface,
            onDestinationSelected: (int index) {
              selectedPageNotifier.value = index;
            },
            indicatorColor: AppColors.primary,
            selectedIndex: selectedPage,
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.surface,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: 'Home',
              ),
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.surface,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.primary,
                      BlendMode.srcIn), // Change color if necessary
                ),
                label: 'Liked',
              ),
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.surface,
                      BlendMode.srcIn), // Change color if necessary
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: 24, // Adjust size as needed
                  height: 24,
                  colorFilter: ColorFilter.mode(AppColors.primary,
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
