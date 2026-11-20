import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_product_shelf/models/product.dart';
import 'package:my_product_shelf/providers/favourites_provider.dart';
import 'package:my_product_shelf/widgets/product_card.dart';

void main() {
  testWidgets('Tapping + Save marks the product as saved', (tester) async {
    // Fake, empty storage: tests run on the computer, not a phone.
    SharedPreferences.setMockInitialValues({});

    final favourites = FavouritesProvider();
    const product = Product(
      id: 1,
      title: 'Travel mug',
      category: 'kitchen',
      price: 19.99,
      thumbnail: '', // empty -> placeholder, so no network in the test
    );

    // Provider ABOVE the widget, just like main() does in the real app.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: favourites,
        child: const MaterialApp(
          home: Scaffold(body: ProductCard(product: product)),
        ),
      ),
    );

    // Before: not saved
    expect(find.text('+ Save'), findsOneWidget);
    expect(favourites.count, 0);

    // Act: tap, then redraw
    await tester.tap(find.text('+ Save'));
    await tester.pump();

    // After: saved in BOTH the UI and the provider
    expect(find.text('Saved'), findsOneWidget);
    expect(favourites.count, 1);
  });
}
