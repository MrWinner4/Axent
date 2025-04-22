import 'package:fashionfrontend/views/pages/profile_settings_page.dart';
import 'package:fashionfrontend/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: const Color.fromARGB(255, 4, 62, 104), //Blue Color
    primary: const Color.fromRGBO(255, 246, 237, 1.0), //Cream Color
    onPrimary: const Color.fromARGB(255, 167, 184, 196),
    secondary: const Color.fromARGB(255, 4, 62, 104), //Blue Color
    tertiary: const Color.fromARGB(255, 207, 36, 36), //Red Color
    surface: const Color.fromARGB(255, 254, 253, 251), //Background Color
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 50,
        left: 15,
        right: 15,
      ),
      child: Column(
        children: <Widget>[
          ListTile(
            textColor: Colors.black,
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
            color: Colors.black,
            height: 1,
            thickness: 1,
          ),
          ListTile(
            textColor: Colors.black,
            trailing: Icon(Icons.leaderboard, color: Colors.black),
            title: const Text("Data"),
            onTap: () {},
          ),
          Divider(
            color: Colors.black,
            height: 1,
            thickness: 1,
          ),
          ListTile(
            textColor: Colors.black,
            trailing: Icon(Icons.logout, color: Colors.black),
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
            color: Colors.black,
            height: 1,
            thickness: 1,
          ),
        ],
      ),
    );
  }
}
