import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/views/widgets/animated_page_route.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _logIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // if(_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    //   setState(() {
    //     _errorMessage = 'Please fill out all fields.';
    //   });
    //   _isLoading = false;
    //   return;
    // }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Navigator.of(context).pushAndRemoveUntil(
        FadeScalePageRoute(page: AuthWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Error Code: ${e.code}'); //TODO!: More elegant handling of errors
      if(e.code == 'invalid-credential') {
        _errorMessage = 'Invalid email or password. Please try again.';
      }
      else if(e.code == 'invalid-email') {
        _errorMessage = 'Please enter a valid email.';
      }
      else {setState(() {
        _errorMessage = e.message;
      });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text("Email"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                cursorColor: AppColors.primary,
                style: TextStyle(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.onSurfaceVariant,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  labelText: 'johndoe@example.com',
                  hintStyle: TextStyle(
                    color: AppColors.primary.withAlpha(128),
                  ),
                labelStyle: TextStyle(
                  color: AppColors.primary.withAlpha(128),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never),
                ),
              const SizedBox(height: 16),
              Text("Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                cursorColor: AppColors.primary,
                style: TextStyle(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.onSurfaceVariant,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  labelText: '••••••••••',
                  labelStyle: TextStyle(
                    color: AppColors.primary.withAlpha(128),
                  ),
                floatingLabelBehavior: FloatingLabelBehavior.never),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _logIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.surface)
                      : Text(
                          'Log In',
                          style: TextStyle(fontSize: 16, color: AppColors.surface),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: 'Don\'t have an account? ',
                    style: TextStyle(
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pop(
                          context,
                        );
                      },
                  ),
                ])),
              )
            ],
          ),
        ),
      ),
    );
  }
}
