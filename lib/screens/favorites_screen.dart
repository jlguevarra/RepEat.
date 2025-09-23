import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_details_screen.dart'; // Make sure this import is correct

class FavoritesScreen extends StatefulWidget {
  final int userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse(
        'http://192.168.100.79/repEatApi/get_favorites.php?user_id=${widget.userId}',
      );

      final response =
      await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          if (mounted) {
            setState(() {
              favorites = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              favorites = []; // Handle case where data is null or not a list
            });
          }
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load favorites. Please try again.';
          debugPrint(e.toString()); // For debugging
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromFavorites(int recipeId) async {
    // Optimistically remove the item from the UI first
    final int removedIndex = favorites.indexWhere((f) => f['recipe_id'] == recipeId);
    if (removedIndex == -1) return; // Item not found

    final Map<String, dynamic> removedItem = favorites[removedIndex];
    setState(() {
      favorites.removeAt(removedIndex);
    });

    try {
      final url =
      Uri.parse('http://192.168.100.79/repEatApi/remove_favorite.php');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'recipe_id': recipeId,
        }),
      );

      final result = jsonDecode(response.body);
      if (result['success'] != true) {
        // If the server failed, add the item back and show an error
        setState(() {
          favorites.insert(removedIndex, removedItem);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Remove failed: ${result['message']}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      }
    } catch (e) {
      // If there was a network error, add the item back
      setState(() {
        favorites.insert(removedIndex, removedItem);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not remove favorite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.grey, size: 60),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadFavorites,
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              "Your Favorite Recipes",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the heart on any recipe to save it here.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // This is the main list view for displaying the favorite cards
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          return _buildFavoriteCard(favorites[index]);
        },
      ),
    );
  }

  /// Builds a single, redesigned favorite recipe card.
  Widget _buildFavoriteCard(Map<String, dynamic> recipe) {
    final recipeId = recipe['recipe_id'] as int;
    final title = recipe['recipe_title'] as String;
    final imageUrl = recipe['recipe_image'] as String?;
    final readyInMinutes = recipe['readyInMinutes'];
    final servings = recipe['servings'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias, // Ensures the image respects the rounded corners
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsScreen(
                recipeId: recipeId,
                recipeTitle: title,
                userId: widget.userId,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            // Background Image
            if (imageUrl != null)
              Ink.image(
                image: NetworkImage(imageUrl),
                height: 220,
                fit: BoxFit.cover,
                child: Container(), // Ink.image needs a child
                onImageError: (_, __) {}, // Handles network image errors gracefully
              )
            else
              Container(
                height: 220,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant_menu,
                    color: Colors.grey, size: 50),
              ),

            // Gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // Content on top of the image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (readyInMinutes != null)
                                _buildSubtitleItem(
                                    Icons.timer_outlined, '$readyInMinutes min'),
                              if (readyInMinutes != null && servings != null)
                                const Text('  •  ',
                                    style: TextStyle(color: Colors.white70)),
                              if (servings != null)
                                _buildSubtitleItem(
                                    Icons.people_outline, '$servings servings'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Favorite button
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                      onPressed: () => _removeFromFavorites(recipeId),
                      tooltip: 'Remove from favorites',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget for the small info items (time, servings).
  Widget _buildSubtitleItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}