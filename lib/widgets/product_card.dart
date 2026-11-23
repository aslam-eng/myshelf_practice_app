import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/favourites_provider.dart';
import '../theme/app_colors.dart';

// One product box. Used by BOTH Home and Saved.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // watch: rebuild this card whenever favourites change.
    final isSaved = context.watch<FavouritesProvider>().isSaved(product.id);
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Image + overlay badge (Stack + Positioned) ----------
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(),
              ),
              if (isSaved)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite, size: 14, color: colors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ---------- Details (Expanded + Column) ----------
          // Expanded gives the text a fixed width, so long titles can't overflow.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),

                // ---------- Price + action (Row) ----------
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonal(
                      // read: just perform the action, no listening needed.
                      onPressed: () =>
                          context.read<FavouritesProvider>().toggle(product),
                      child: Text(isSaved ? 'Saved' : '+ Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (product.thumbnail.isEmpty) return _placeholder();
    return Image.network(
      product.thumbnail,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      // Broken URL or offline -> placeholder instead of an error.
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 96,
      height: 96,
      color: AppColors.placeholder,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}
