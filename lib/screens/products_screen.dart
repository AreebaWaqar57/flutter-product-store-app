import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_api_service.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/product_card.dart';

import 'product_details_screen.dart';

import 'product_form_screen.dart';

enum ViewState { loading, success, error }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = ProductApiService();
  final _searchCtrl = TextEditingController();
  List<Product> _products = [];
  ViewState _state = ViewState.loading;
  String _error = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) setState(() => _state = ViewState.loading);
    try {
      final data = await _service.getProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
        _state = ViewState.success;
      });
    } on ApiException catch (e) {
      _fail(e.message, showLoader);
    } catch (_) {
      _fail('something went wrong.', showLoader);
    }
  }

  void _fail(String msg, bool fullScreen) {
    if (!mounted) return;
    if (fullScreen || _products.isEmpty) {
      setState(() {
        _error = msg;
        _state = ViewState.error;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (created != null && mounted) {
      setState(() {
        _products.insert(0, created);
      });
    }
  }

  void _openDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          onUpdated: (p) => setState(() {
            final i = _products.indexWhere((x) => x.id == p.id);
            if (i != -1) _products[i] = p;
          }),
          onDeleted: (p) =>
              setState(() => _products.removeWhere((x) => x.id == p.id)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by title',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ViewState.loading:
        return const LoadingWidget(message: 'Loading products...');
      case ViewState.error:
        return AppErrorWidget(message: _error, onRetry: _load);
      case ViewState.success:
        final items = _filtered;
        return RefreshIndicator(
          onRefresh: () => _load(showLoader: false),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No products available.'
                            : 'No products match "$_query".',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(
                    product: items[i],
                    onTap: () => _openDetails(items[i]),
                  ),
                ),
        );
    }
  }
}
