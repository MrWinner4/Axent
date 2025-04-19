import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
            color: const Color.fromARGB(255, 254, 251, 247),
            child: SwipeableCard(user: user)),
      )
    );
  }
}