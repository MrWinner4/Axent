import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:fashionfrontend/views/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fashionfrontend/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool tac = false;

  showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
          height: MediaQuery.of(context).size.height * .9,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Terms and Conditions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          //!TERMS AND CONDITIONS HERE
                          "Example TOC...",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ))))
            ],
          )),
    );
  }

  final user = FirebaseAuth.instance.currentUser;
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (tac == true) {
      if (_nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty) {
        try {
          final credential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          // Set display name
          await credential.user?.updateDisplayName(_nameController.text);

          final newUser = FirebaseAuth.instance.currentUser;
          await newUser?.reload(); // Force refresh
          final refreshedUser = FirebaseAuth.instance.currentUser;


          final idToken = await refreshedUser!.getIdToken();
          print(idToken);
          await Dio().post(
            'https://axentbackend.onrender.com/preferences/create_user/',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken', // Send token in headers
              },
            ),
            data: {
              'name': _nameController
                  .text, // Only send name, email is extracted from token
            },
          );
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AuthWrapper()),
          );
        } on FirebaseAuthException catch (e) {
          setState(() {
            _errorMessage = e.message;
          });
        } catch (e) {
          setState(() {
            print(e);
            _errorMessage = e.toString();
          });
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
      else{
        _errorMessage = "Please fill out all fields.";
      }
    } else {
      _errorMessage = "Please agree to the terms and conditions.";
      _isLoading = false;
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text("Name"),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    labelText: 'John Doe',
                    labelStyle: TextStyle(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never),
              ),
              const SizedBox(height: 16),
              Text("Email"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    labelText: 'johndoe@example.com',
                    labelStyle: TextStyle(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never),
              ),
              const SizedBox(height: 16),
              Text("Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    labelText: '••••••••••',
                    labelStyle: TextStyle(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(128),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Checkbox(
                    value: tac,
                    onChanged: (bool? newValue) {
                      setState(() {
                        tac = newValue!;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    semanticLabel: "I Agree to Terms and Conditions",
                  ),
                  RichText(
                    text: TextSpan(
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Color.fromARGB(255, 4, 62, 104)),
                        children: [
                          TextSpan(text: ' I agree to the '),
                          TextSpan(
                              text: 'Terms and conditions',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  showTermsAndConditions(context);
                                })
                        ]),
                  )
                ],
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: 'Log In',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogInPage()),
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
