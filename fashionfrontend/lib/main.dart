import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'models/card_queue_model.dart'; // Your provider model.

import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Make sure Flutter is fully initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Use your firebase_options.dart
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => CardQueueModel(),
      child: const MainPage(),
    ),);
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.light, 
      seedColor: const Color.fromARGB(255, 4, 62, 104), //Blue Color
      primary: const Color.fromRGBO(255, 246, 237, 1.0), //Cream Color
      onPrimary: Color.fromARGB(255, 167, 184, 196),
      secondary: const Color.fromARGB(255, 4, 62, 104), //Blue Color
      tertiary: const Color.fromARGB(255, 207, 36, 36), //Red Color
      surface: const Color.fromARGB(255, 254, 253, 251), //Background Color
    );
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  color: colorScheme.surface,
                  fontWeight: FontWeight.bold,
                ); // For the selected item
              }
              return TextStyle(fontSize: 12, color: colorScheme.surface); // For unselected items
            },
          ),
        ),
        colorScheme: colorScheme,
        iconTheme: IconThemeData(
        ),
      ),
      home: AuthWrapper(),
    );
  }
}