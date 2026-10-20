import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_api_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductApiService();

  late final _title = TextEditingController(text: widget.product?.title);
  late final _price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final _desc = TextEditingController(text: widget.product?.description);
  late final _category = TextEditingController(text: widget.product?.category);
  late final _image = TextEditingController(text: widget.product?.thumbnail);

  bool _saving = false;
  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    for (final c in [_title, _price, _desc, _category, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _validatePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Price must be greater than 0';
    return null;
  }

  String? _validateUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'Image URL is required';
    final uri = Uri.tryParse(v.trim());
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final base =
        widget.product ??
        const Product(
          id: 0,
          title: '',
          description: '',
          price: 0,
          category: '',
          thumbnail: '',
        );
    final draft = base.copyWith(
      title: _title.text.trim(),
      price: double.parse(_price.text.trim()),
      description: _desc.text.trim(),
      category: _category.text.trim(),
      thumbnail: _image.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final result = _isEdit
          ? await _service.updateProduct(draft)
          : await _service.addProduct(draft);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, result);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Product updated' : 'Product created'),
        ),
      );
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_title, 'Title', validator: (v) => _required(v, 'Title')),
              _field(
                _price,
                'Price',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: _validatePrice,
              ),
              _field(
                _desc,
                'Description',
                maxLines: 4,
                validator: (v) => _required(v, 'Description'),
              ),
              _field(
                _category,
                'Category',
                validator: (v) => _required(v, 'Category'),
              ),
              _field(
                _image,
                'Image URL',
                keyboard: TextInputType.url,
                validator: _validateUrl,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Create product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        enabled: !_saving,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
