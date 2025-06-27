import 'package:fashionfrontend/views/pages/profile_settings_page.dart';
import 'package:fashionfrontend/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionfrontend/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PageStorageKey('settings'),
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.only(
          top: 50,
          left: 15,
          right: 15,
        ),
        child: Column(
          children: <Widget>[
            ListTile(
              textColor: AppColors.onSurface,
              title: const Text("Profile"),
              trailing: SvgPicture.asset(
                'assets/icons/Person.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfileSettingsPage();
                }));
              },
              style: ListTileStyle.drawer,
            ),
            Divider(
              color: AppColors.onSurface,
              height: 1,
              thickness: 1,
            ),
            ListTile(
              textColor: AppColors.onSurface,
              trailing: Icon(Icons.leaderboard, color: AppColors.onSurface),
              title: const Text("Data"),
              onTap: () {},
            ),
            Divider(
              color: AppColors.onSurface,
              height: 1,
              thickness: 1,
            ),
            ListTile(
              textColor: AppColors.onSurface,
              trailing: Icon(Icons.logout, color: AppColors.onSurface),
              title: const Text("Logout"),
              onTap: () async {
                // Sign out the user
                await FirebaseAuth.instance.signOut();
                // Back to Welcome Screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => WelcomePage()),
                  (route) => false,
                );
              },
            ),
            Divider(
              color: AppColors.onSurface,
              height: 1,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
