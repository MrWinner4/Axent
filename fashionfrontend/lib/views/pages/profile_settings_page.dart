import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(
          top: 50.0,
          left: 20.0,
          right: 20.0,
        ),
        child: Column(
          children: [
            const Text("profile settings page"),
          ],
        )
      ),
    );
  }
}