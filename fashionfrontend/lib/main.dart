import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/providers/filters_provider.dart';
import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/models/card_queue_model.dart'; 
import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/firebase_options.dart';

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
        ChangeNotifierProvider(create: (_) => PreviousProductModel()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
      ],
      child: const MainPage(),
    ),
  );
}// Then in your MaterialApp:


/*

theme: ThemeData(
    colorScheme: AppColors.lightScheme,
    useMaterial3: true, // This is important for Material 3 compatibility
  ),
  darkTheme: ThemeData(
    
    useMaterial3: true,
  ),
  themeMode: ThemeMode.system, // Follows system theme
*/

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: AppColors.lightScheme,
        useMaterial3: true,
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
      darkTheme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: AppColors.darkScheme,
        useMaterial3: true,
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
