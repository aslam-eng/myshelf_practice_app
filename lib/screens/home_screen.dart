import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/products_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/message_view.dart';
import '../widgets/page_title.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';

// Products, loading and error live in ProductsProvider.
// This screen only DRAWS that state; its own objects are the two controllers.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Tells us how far the list is scrolled (for loading the next page).
  final ScrollController _scrollController = ScrollController();

  // ---------- Lifecycle ----------
  // Order: initState (once) -> build (many times) -> dispose (once).
  // The first product load starts in main.dart (provider create), not here.
  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen: initState');
    _scrollController.addListener(_onScroll); // one-time setup
  }

  @override
  void dispose() {
    debugPrint('HomeScreen: dispose');
    _searchController.dispose(); // we created them, so we clean them up
    _scrollController.dispose();
    super.dispose();
  }

  // Runs MANY times per second while the list moves.
  void _onScroll() {
    final position = _scrollController.position;
    // Within 200 px of the bottom -> ask for the next page early,
    // so the user rarely sees the spinner.
    if (position.pixels >= position.maxScrollExtent - 200) {
      // No check here: loadMore()'s guard ignores the extra calls.
      context.read<ProductsProvider>().loadMore();
    }
  }

  // ---------- Data ----------
  // Pull-to-refresh keeps the current products. If it fails, the provider
  // rethrows the error and we show it in a SnackBar.
  Future<void> _refresh() async {
    // Grab these BEFORE the await (context may change while waiting).
    final products = context.read<ProductsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await products.loadProducts(showLoader: false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not refresh: $e')),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: build');
    final name = context.watch<ProfileProvider>().name;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle('My Shelf'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(name.isEmpty ? 'Hello there' : 'Hello, $name'),
                  ),
                  FilledButton.tonal(
                    // Bottom sheet: the form slides up over Home.
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        builder: (_) => const AddProductScreen(),
                      );
                    },
                    child: const Text('+ Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                // read: send the text without rebuilding this whole screen.
                onChanged: (value) =>
                    context.read<ProductsProvider>().setSearchText(value),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Explore products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Consumer: only this count rebuilds when products change.
                  Consumer<ProductsProvider>(
                    builder: (context, products, child) {
                      // total = matches on the SERVER, not just loaded ones.
                      return Text(
                        products.isLoading ? '' : '${products.total} items',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Expanded: the list gets the remaining height (bounded space).
              Expanded(
                // Consumer: only the list area rebuilds when products change.
                child: Consumer<ProductsProvider>(
                  builder: (context, products, child) =>
                      _buildContent(products),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shows exactly ONE state: loading, error, empty, or the list.
  Widget _buildContent(ProductsProvider products) {
    if (products.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.error != null) {
      return MessageView(
        icon: Icons.wifi_off,
        message: products.error!,
        buttonText: 'Retry',
        onPressed: products.loadProducts,
      );
    }

    final visible = products.visibleProducts;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          // activeQuery = the text these (zero) results belong to.
          products.activeQuery.isEmpty
              ? 'No products available'
              : 'No products match "${products.activeQuery}"',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // One extra slot at the end while more pages exist (or the last one failed).
    // Search results are paginated too, so no "not while searching" rule.
    final showFooter = products.hasMore || products.loadMoreError != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: visible.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visible.length) return _buildFooter(products);
          return ProductCard(product: visible[index]);
        },
      ),
    );
  }

  // Last item of the list: a small spinner, or the error with a Retry button.
  Widget _buildFooter(ProductsProvider products) {
    if (products.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              products.loadMoreError!,
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: products.retryLoadMore,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
