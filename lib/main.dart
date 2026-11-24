import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/favourites_provider.dart';
import 'providers/products_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

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
        // Start the first load HERE, not in HomeScreen.initState:
        // loadProducts() calls notifyListeners() right away, and doing that
        // while Flutter is building a screen throws an error.
        // At create time nobody is listening yet, so it is safe.
        ChangeNotifierProvider(
          create: (_) => ProductsProvider()..loadProducts(),
        ),
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
      theme: AppTheme.light,
      home: const MainShell(), // bottom navigation: Home / Saved / Profile
    );
  }
}
