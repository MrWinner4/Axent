import 'package:fashionfrontend/views/pages/welcome_page.dart';
import 'package:fashionfrontend/views/widget_tree.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
       builder: (context, snapshot) {
        // Firebase is still checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          return WidgetTree();
        }

        if (!snapshot.hasData){
          return WelcomePage();
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

       }
      );
  }
}