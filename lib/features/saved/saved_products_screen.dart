import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedProductsScreen extends StatelessWidget {
  const SavedProductsScreen({super.key});

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF09090D) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF14141D) : Colors.white;
    final border = isDark ? const Color(0xFF282838) : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Saved Products'),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No saved products yet.',
                style: TextStyle(color: sub, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final product = doc.data();

              final name = product['name']?.toString() ?? 'Unknown product';
              final price = product['price']?.toString() ?? 'No price';
              final store = product['store']?.toString() ?? 'Unknown store';
              final image = product['image']?.toString() ?? '';
              final url = product['url']?.toString() ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _fallbackImage(),
                            )
                          : _fallbackImage(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFFFF5A52),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sold by $store',
                            style: TextStyle(color: sub, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: url.isNotEmpty
                                    ? () => _openUrl(url)
                                    : null,
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('View'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  await doc.reference.delete();
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFFFF5A52),
      ),
    );
  }
}