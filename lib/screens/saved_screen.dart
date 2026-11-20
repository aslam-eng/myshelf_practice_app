import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favourites_provider.dart';
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
              const Text(
                'Saved products',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your favourites, in one place.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${favourites.count} saved',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: saved.isEmpty
                    ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No saved products yet'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onBrowse,
            child: const Text('Browse products'),
          ),
        ],
      ),
    );
  }
}
