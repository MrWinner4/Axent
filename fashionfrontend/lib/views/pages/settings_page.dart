import 'package:fashionfrontend/views/pages/profile_settings_page.dart';
import 'package:fashionfrontend/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:dio/dio.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PageStorageKey('settings'),
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: EdgeInsets.only(top: 50, left: 15, right: 15),
        child: Column(
          children: <Widget>[
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 24),
            SettingsBlock(
              child: Column(
                children: [
                  EmailSettingsTile(),
                  SettingsTile(
                    title: "Language",
                    icon: Icons.language,
                    onTap: () {
                      // Navigate to Language settings
                    },
                  ),
                  SettingsTile(
                    title: "Theme",
                    icon: Icons.color_lens,
                    onTap: () {
                      // Navigate to Theme settings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailSettingsTile extends StatefulWidget {
  @override
  State<EmailSettingsTile> createState() => _EmailSettingsTileState();
}

class _EmailSettingsTileState extends State<EmailSettingsTile> {
  String? _email = FirebaseAuth.instance.currentUser?.email;
  bool _isLoading = false;

  Future<void> _changeEmailDialog() async {
    final TextEditingController controller = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Change Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'New Email',
                      errorText: error,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      labelText: 'Type email again',
                      errorText: error,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: _isLoading ? CircularProgressIndicator() : Text('Change'),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final newEmail = controller.text.trim();
                          final confirmEmail = confirmController.text.trim();
                          if (!RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}").hasMatch(newEmail)) {
                            setState(() => error = 'Enter a valid email');
                            return;
                          }
                          if (newEmail != confirmEmail) {
                            setState(() => error = 'Emails do not match');
                            return;
                          }
                          setState(() => _isLoading = true);
                          try {
                            // Update Firebase
                            await FirebaseAuth.instance.currentUser?.updateEmail(newEmail);
                            await FirebaseAuth.instance.currentUser?.reload();
                            final user = FirebaseAuth.instance.currentUser;
                            final idToken = await user?.getIdToken();
                            // Update backend
                            await Dio().post(
                              'https://axentbackend.onrender.com/preferences/update_email/',
                              options: Options(
                                headers: {
                                  'Authorization': 'Bearer $idToken',
                                },
                              ),
                              data: {
                                'email': newEmail,
                              },
                            );
                            setState(() {
                              _email = newEmail;
                              error = null;
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Email updated successfully')),
                            );
                          } catch (e) {
                            setState(() => error = 'Failed to update email: ${e.toString()}');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: "Email",
      icon: Icons.email,
      trailing: _email ?? "",
      onTap: _changeEmailDialog,
    );
  }
}

class SettingsBlock extends StatelessWidget {
  final Widget child;
  const SettingsBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String trailing;
  final IconData icon;
  final Function()? onTap;
  const SettingsTile(
      {required this.title, required this.icon, required this.onTap, this.trailing = ""});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      textColor: AppColors.onSurface,
      leading: Icon(icon, color: AppColors.onSurface),
      title: Text(title),
      onTap: onTap,
      style: ListTileStyle.drawer,
      trailing: Text(trailing, style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
    );
  }
}
