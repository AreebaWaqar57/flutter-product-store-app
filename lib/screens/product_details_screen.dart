import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_api_service.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onUpdated,
    required this.onDeleted,
  });
  final Product product;
  final ValueChanged<Product> onUpdated;
  final ValueChanged<Product> onDeleted;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _service = ProductApiService();
  late Product _product = widget.product;
  bool _refreshing = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_product.isLocal) return;
    setState(() => _refreshing = true);
    try {
      final fresh = await _service.getProduct(_product.id);
      if (!mounted) return;
      setState(() => _product = fresh);
    } on ApiException catch (e) {
      _snack('Could not refresh details: ${e.message}');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: _product)),
    );
    if (updated != null && mounted) {
      setState(() => _product = updated);
      widget.onUpdated(updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${_product.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteProduct(_product);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      widget.onDeleted(_product);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Product deleted')));
    } on ApiException catch (e) {
      _snack('Delete failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        bottom: _refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ProductImage(url: p.thumbnail, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '\$${p.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(p.category)),
                    if (p.brand != null) Chip(label: Text(p.brand!)),
                    if (p.rating != null) Chip(label: Text('★ ${p.rating}')),
                    if (p.stock != null) Chip(label: Text('Stock: ${p.stock}')),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Description', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(p.description),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleting ? null : _edit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _deleting ? null : _delete,
                        icon: _deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete),
                        label: const Text('Delete'),
                      ),
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
}
