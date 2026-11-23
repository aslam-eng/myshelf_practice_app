import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favourites_provider.dart';
import '../widgets/info_badge.dart';
import '../widgets/message_view.dart';
import '../widgets/page_title.dart';
import '../widgets/product_card.dart';

// No setState here: all data comes from FavouritesProvider.
class SavedScreen extends StatelessWidget {
  final VoidCallback onBrowse; // given by MainShell: switches to the Home tab

  const SavedScreen({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    // watch: rebuild instantly when anything is saved or removed.
    final favourites = context.watch<FavouritesProvider>();
    final saved = favourites.saved;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle('Saved products'),
              const SizedBox(height: 8),
              const Text(
                'Your favourites, in one place.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              InfoBadge('${favourites.count} saved'),
              const SizedBox(height: 16),
              Expanded(
                child: saved.isEmpty
                    ? MessageView(
                        icon: Icons.favorite_border,
                        message: 'No saved products yet',
                        buttonText: 'Browse products',
                        onPressed: onBrowse,
                      )
                    : ListView.builder(
                        itemCount: saved.length,
                        itemBuilder: (context, index) =>
                            ProductCard(product: saved[index]),
                      ),
              ),
              if (saved.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tap Saved to remove an item.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
