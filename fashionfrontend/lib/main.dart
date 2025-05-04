import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'models/card_queue_model.dart'; // Your provider model.
import 'providers/search_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Make sure Flutter is fully initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use your firebase_options.dart
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardQueueModel()),
        ChangeNotifierProvider(create: (_) => PreviousShoeModel()),
        ChangeNotifierProvider(create: (_) => LikedShoesModel()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const MainPage(),
    ),
  );
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(
              255, 4, 62, 104), // Change this to your desired color
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 254, 253, 251),
                  fontWeight: FontWeight.bold,
                ); // For the selected item
              }
              return TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 254, 253, 251),
              ); // For unselected items
            },
          ),
        ),
        iconTheme: IconThemeData(),
      ),
      home: AuthWrapper(),
    );
  }
}
