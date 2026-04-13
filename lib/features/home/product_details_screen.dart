import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  Future<void> _openProductUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image']?.toString() ?? '';
    final productUrl = product['url']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              product['name']?.toString() ?? 'Unknown product',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text('Store: ${product['store'] ?? '-'}'),
            const SizedBox(height: 6),
            Text('Price: ${product['price'] != null ? '\$${product['price']}' : '-'}'),
            const SizedBox(height: 6),
            Text('Rating: ${product['rating'] ?? '-'}'),
            const SizedBox(height: 16),
            Text(
              product['reason']?.toString() ?? '',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: productUrl.isNotEmpty
                    ? () => _openProductUrl(productUrl)
                    : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}