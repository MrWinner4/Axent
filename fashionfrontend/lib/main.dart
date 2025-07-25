import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/providers/filters_provider.dart';
import 'package:fashionfrontend/providers/liked_products_provider.dart';
import 'package:fashionfrontend/providers/wardrobes_provider.dart';
import 'package:fashionfrontend/views/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/models/card_queue_model.dart'; 
import 'package:fashionfrontend/providers/search_provider.dart';
import 'package:fashionfrontend/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize filters provider
  final filtersProvider = FiltersProvider();
  await filtersProvider.loadFilters();

  // Initialize liked products provider
  final likedProductsProvider = LikedProductsProvider();

  // Initialize wardrobes provider and load data
  final wardrobesProvider = WardrobesProvider();
  await wardrobesProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardQueueModel()),
        ChangeNotifierProvider(create: (_) => PreviousProductModel()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider.value(value: filtersProvider),
        ChangeNotifierProvider.value(value: likedProductsProvider),
        ChangeNotifierProvider.value(value: wardrobesProvider),
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
      title: 'Fashion App',
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
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                );
              }
              return TextStyle(
                fontSize: 12,
                color: AppColors.surface,
              );
            },
          ),
        ),
        iconTheme: IconThemeData(),
      ),
      home: AuthWrapper(),
    );
  }
}
