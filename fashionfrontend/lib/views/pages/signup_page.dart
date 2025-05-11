import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:fashionfrontend/views/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

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

  final user = FirebaseAuth.instance.currentUser;
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      await Dio().post(
        'https://axentbackend.onrender.com/api/create_user/', //Why isn't it creating a new
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken', // Send token in headers
          },
        ),
        data: {
          'name': _nameController.text, // Only send name, email is extracted from token
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
      backgroundColor: Color.fromARGB(255, 252, 246, 237),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/AxentLogo.png',
                height: 200,
              ),
              const SizedBox(height: 75),
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 75),
              TextField(
                controller: _nameController,
                cursorColor: Color.fromARGB(255, 4, 62, 104),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 238, 240, 243),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  labelText: 'Username',
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 4, 62, 104),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                cursorColor: Color.fromARGB(255, 4, 62, 104),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 238, 240, 243),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 4, 62, 104),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                cursorColor: Color.fromARGB(255, 4, 62, 104),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 238, 240, 243),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 4, 62, 104),
                      width: 1,
                    ),
                  ),
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 4, 62, 104),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Color.fromARGB(255, 4, 62, 104),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 4, 62, 104),
                    ),
                  ),
                  TextSpan(
                    text: 'Log In',
                    style: TextStyle(
                      color: Color.fromARGB(255, 4, 62, 104),
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
