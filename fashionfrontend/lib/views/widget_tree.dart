import 'package:fashionfrontend/data/notifiers.dart';
//import 'package:fashionfrontend/views/pages/collections_page.dart';
import 'package:fashionfrontend/views/pages/home_page.dart';
import 'package:fashionfrontend/views/pages/heart_page.dart';
import 'package:fashionfrontend/views/pages/settings_page.dart';
import 'package:fashionfrontend/views/widgets/navbar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


//TODO: Talk about what needs to be in the settings page
//TODO: 




class WidgetTree extends StatelessWidget {

  WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;
    final List<Widget> pages = [
      HomePage(user: user),
      HeartPage(),
      //CollectionsPage(), //!THIS IS A COMING FEATURE, NOT IN VERSION 1.0
      SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: DefaultTextStyle(
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 4, 62, 104)),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Hi, ',
                ),
                TextSpan(
                  text: user.displayName ?? 'User'
                ),
              ]),
            ),
          ),
        ),
      bottomNavigationBar: NavbarWidget(),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (BuildContext context, dynamic selectedPage, Widget? child) {
          return pages.elementAt(selectedPage);
        },
      ),
    );
  }
}
