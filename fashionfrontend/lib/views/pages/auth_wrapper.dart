import 'package:fashionfrontend/data/notifiers.dart';
import 'package:fashionfrontend/views/pages/heart_page.dart';
import 'package:fashionfrontend/views/pages/home_page.dart';
import 'package:fashionfrontend/views/pages/settings_page.dart';
import 'package:fashionfrontend/views/pages/welcome_page.dart';
import 'package:fashionfrontend/views/widgets/navbar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? user;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages once in initState
    pages = const [
      HomePage(key: PageStorageKey('home')),
      HeartPage(key: PageStorageKey('heart')),
      SettingsPage(key: PageStorageKey('settings')),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            user ??= FirebaseAuth.instance.currentUser!;

            final gradient = LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 62, 104),
                Color.fromARGB(255, 8, 123, 206)
              ],
            );
            return Scaffold(
              appBar: AppBar(
                  backgroundColor: Color.fromARGB(255, 251, 252, 254),
                  toolbarHeight: 40,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 4, 62, 104)),
                      children: [
                        TextSpan(text: 'Hi, '),
                        TextSpan(
                          text: user!.displayName ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = gradient.createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        TextSpan(text: " 👋")
                      ],
                    ),
                  )),
              body: ValueListenableBuilder(
                  valueListenable: selectedPageNotifier,
                  builder: (context, selectedPage, child) {
                    return IndexedStack(
                      index: selectedPage,
                      children: pages,
                    );
                  }),
              bottomNavigationBar: NavbarWidget(),
            );
          }
          return WelcomePage();
        });
  }
}
