import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/favourites_provider.dart';
import 'providers/products_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  // Needed because shared_preferences (native code) is used before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved data BEFORE showing the app, so every screen's initState
  // (e.g. Profile filling the name field) sees the saved values.
  final favouritesProvider = FavouritesProvider();
  final profileProvider = ProfileProvider();
  await favouritesProvider.load();
  await profileProvider.load();

  runApp(
    // Providers sit ABOVE MaterialApp, so every screen (including pages
    // opened with Navigator.push) can find them.
    MultiProvider(
      providers: [
        // .value = hand over objects we already created.
        // They live for the whole app, so no manual dispose is needed.
        ChangeNotifierProvider.value(value: favouritesProvider),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Product Shelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainShell(), // bottom navigation: Home / Saved / Profile
    );
  }
}
