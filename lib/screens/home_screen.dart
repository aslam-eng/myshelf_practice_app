import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../providers/profile_provider.dart';
import '../services/product_service.dart';
import '../widgets/page_title.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  // Local UI state (setState). Favourites are NOT here: they live in Provider.
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error; // null = no error

  // ---------- Lifecycle ----------
  // Order: initState (once) -> build (many times) -> dispose (once).
  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen: initState');
    _loadProducts(); // one-time loading starts here, never in build
  }

  @override
  void dispose() {
    debugPrint('HomeScreen: dispose');
    _searchController.dispose(); // we created it, so we clean it up
    super.dispose();
  }

  // ---------- Data ----------
  // showLoader = false for pull-to-refresh (RefreshIndicator has its own spinner).
  Future<void> _loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final products = await _productService.fetchProducts();
      if (!mounted) return; // screen destroyed while waiting? stop.
      setState(() {
        _products = products; // REPLACE, so refresh never duplicates
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Refresh failed, but we still have products: keep showing them.
      if (_products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh: $e')),
        );
        return;
      }

      setState(() {
        _error = e.toString(); // nothing to show, so use the error page
        _isLoading = false;
      });
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
                    // push: place the form on top; its back arrow pops it.
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
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
                  // Consumer: only this count rebuilds while searching.
                  Consumer<ProductsProvider>(
                    builder: (context, search, child) {
                      final count = search.filter(_products).length;
                      return Text(
                        '$count items',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Expanded: the list gets the remaining height (bounded space).
              Expanded(
                // Consumer: only the list area rebuilds while searching.
                child: Consumer<ProductsProvider>(
                  builder: (context, search, child) {
                    return _buildContent(
                      search.filter(_products),
                      search.searchText,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shows exactly ONE state: loading, error, empty, or the list.
  Widget _buildContent(List<Product> products, String searchText) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Text(
          searchText.isEmpty
              ? 'No products available'
              : 'No products match "$searchText"',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(showLoader: false),
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}
