import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../widgets/field_label.dart';
import '../widgets/info_badge.dart';
import '../widgets/status_box.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>(); // "remote control" for the Form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ProductService _productService = ProductService();

  // Local UI state (setState):
  bool _isSending = false;
  int? _createdId; // set on success
  String? _error; // set on failure

  // ---------- Lifecycle (logged for the demo) ----------
  // Open screen: initState -> build. Type: build again. Back: dispose.
  @override
  void initState() {
    super.initState();
    debugPrint('AddProductScreen: initState');
  }

  @override
  void dispose() {
    debugPrint('AddProductScreen: dispose');
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------- Validation (return null = valid, String = error text) ----------
  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter a title';
    if (text.length < 3) return 'Title must be at least 3 characters';
    return null;
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    if (price == null || !price.isFinite) return 'Please enter a valid number';
    if (price <= 0) return 'Price must be greater than zero';
    return null;
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    if (_isSending) return; // Guard 1: ignore a second quick tap

    // Remove the old result first, so it can't sit beside a new error.
    setState(() {
      _createdId = null;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return; // shows errors under fields

    FocusScope.of(context).unfocus(); // close the keyboard
    setState(() => _isSending = true);

    try {
      final id = await _productService.addProduct(
        title: _titleController.text.trim(),
        price: double.parse(_priceController.text.trim()), // safe: validated
      );
      if (!mounted) return; // user left during the request
      setState(() => _createdId = id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString()); // inputs kept, user can retry
    } finally {
      // Runs on success AND failure: loading always ends.
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    debugPrint('AddProductScreen: build');

    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      // Scrollable, so the keyboard can never hide the button.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoBadge('Demo request'),
              const SizedBox(height: 24),
              const FieldLabel('Product title'),
              TextFormField(
                controller: _titleController,
                validator: _validateTitle,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Travel mug'),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Price (USD)'),
              TextFormField(
                controller: _priceController,
                validator: _validatePrice,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'e.g. 19.99'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Guard 2: null = disabled while sending
                  onPressed: _isSending ? null : _submit,
                  child: Text(_isSending ? 'Sending...' : 'Send request'),
                ),
              ),
              const SizedBox(height: 16),

              if (_createdId != null)
                StatusBox(
                  type: StatusType.success,
                  title: 'Demo request successful',
                  message: 'Product ID: $_createdId',
                ),

              if (_error != null) ...[
                StatusBox(
                  type: StatusType.error,
                  title: 'Request failed',
                  message: _error,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _isSending ? null : _submit,
                  child: const Text('Try again'),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'This demo does not permanently add a product to the catalogue.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
