import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final Article article;

  const DetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    // Obtain active user uid
    final user = authService.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Slivers AppBar for parallax scrolling with big cover image
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (uid.isNotEmpty)
                StreamBuilder<bool>(
                  stream: firestoreService.isFavorite(uid, article.id),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            if (isFav) {
                              await firestoreService.removeFavorite(uid, article.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Removed from favorites.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            } else {
                              await firestoreService.addFavorite(uid, article);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to favorites!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update favorite: $e')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_img_${article.id}',
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.cardColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.cardColor,
                    child: const Icon(Icons.broken_image, size: 60),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Publisher and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                        ),
                        child: Text(
                          article.newsSite,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.accentNeonBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy • HH:mm').format(article.publishedAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          height: 1.3,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 24, thickness: 1),
                  const SizedBox(height: 8),
                  // Section Header
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentNeonOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Summary Text
                  Text(
                    article.summary.isNotEmpty
                        ? article.summary
                        : 'No summary available for this space bulletin. Tap below to visit the official publisher page and read the full report.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          color: AppTheme.textPrimary.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
