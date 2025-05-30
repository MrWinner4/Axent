import 'dart:async';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trends_page.dart';

const String likedProductsBaseUrl =
    'https://axentbackend.onrender.com/preferences';
const String wardrobesBaseUrl = 'https://axentbackend.onrender.com/wardrobes';

class HeartPage extends StatefulWidget {
  const HeartPage({super.key});

  @override
  HeartPageState createState() => HeartPageState();
}

class HeartPageState extends State<HeartPage>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Wardrobe>> _wardrobesNotifier = ValueNotifier([]);
  bool _isLoading = true;
  bool _isWardrobesLoading = true;

  @override
  bool get wantKeepAlive => true;

  void refreshLikedProducts() {
    setState(() {
      _isLoading = true;
    });
    fetchLikedProducts();
  }

  void refreshWardrobes() {
    setState(() {
      _isWardrobesLoading = true;
    });
    fetchWardrobes();
  }

  @override
  void initState() {
    print("init");
    super.initState();
    fetchLikedProducts();
    fetchWardrobes();
  }

  @override
  void dispose() {
    _productsNotifier.dispose();
    _wardrobesNotifier.dispose();
    super.dispose();
  }

  Future<void> fetchLikedProducts() async {
    try {
      // Get the Firebase ID token
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;

      // Send the ID token in the Authorization header
      final response = await Dio().get(
        '$likedProductsBaseUrl/liked_products/',
        options: Options(
          headers: {
            'Authorization':
                'Bearer $idToken', // Pass the token in Authorization header
          },
        ),
      );

      // Update the products list
      if (mounted) {
        _productsNotifier.value = response.data;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching liked products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchWardrobes() async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;

      // Get user ID from token
      final decodedToken =
          await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      final userId = decodedToken.claims?['user_id'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      final response = await Dio().get(
        '$wardrobesBaseUrl/user/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
        queryParameters: {
          'firebase_uid': userId,
        },
      );

      if (mounted && response.data != null) {
        try {
          final List<dynamic> data = response.data as List<dynamic>;

          _wardrobesNotifier.value =
              data.map((json) => Wardrobe.fromJson(json)).toList();
          setState(() {
            _isWardrobesLoading = false;
          });
        } catch (e) {
          _wardrobesNotifier.value = [];
          setState(() {
            _isWardrobesLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWardrobesLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wardrobes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> createWardrobe(BuildContext context, bool mounted) async {
    try {
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final controller = TextEditingController();

          return AlertDialog(
            title: const Text('Create New Wardrobe'),
            content: TextField(
              autofocus: true,
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter wardrobe name',
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(controller.text);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );

      if (name == null || name.isEmpty) {
        return;
      }

      // Now create the wardrobe
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      final decodedToken =
          await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      final userId = decodedToken.claims?['user_id'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context, // Use the original context here
        barrierDismissible: false,
        builder: (BuildContext loadingContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Creating wardrobe...'),
            ],
          ),
        ),
      );

      try {
        await Dio().post(
          '$wardrobesBaseUrl/',
          data: {
            'name': name,
            'user': userId,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wardrobe created successfully: $name'),
              backgroundColor: Colors.green,
            ),
          );
          refreshWardrobes();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create wardrobe: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        rethrow;
      }
    } catch (e) {
      print('Error creating wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteWardrobe(String wardrobeId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().delete(
        '$wardrobesBaseUrl/$wardrobeId/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error deleting wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addToWardrobe(String wardrobeId, String productId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().post(
        '$wardrobesBaseUrl/$wardrobeId/add_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error adding to wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> removeFromWardrobe(String wardrobeId, String productId) async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      await Dio().post(
        '$wardrobesBaseUrl/$wardrobeId/remove_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (mounted) {
        refreshWardrobes();
      }
    } catch (e) {
      print('Error removing from wardrobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from wardrobe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build to ensure keepAlive works
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: TabBar(
            tabs: const [
              Tab(text: 'Trends'),
              Tab(text: 'Wardrobes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const TrendsPage(),
            // Heart tab content
            Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Your Wardrobes",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ValueListenableBuilder<List<dynamic>>(
                            valueListenable: _productsNotifier,
                            builder: (context, products, _) {
                              if (_isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (products.isEmpty) {
                                return const Center(
                                    child: Text("No liked products."));
                              }
                              // Take the last 3 items (most recent)
                              final recentProducts = products.length >= 3
                                  ? products.sublist(products.length - 3)
                                  : products;
                              return LikedProductsSection(
                                  Products: recentProducts
                                      .cast<Map<String, dynamic>>());
                            },
                          ),
                          const SizedBox(height: 40),
                          ValueListenableBuilder<List<Wardrobe>>(
                            valueListenable: _wardrobesNotifier,
                            builder: (context, wardrobes, _) {
                              if (_isWardrobesLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (wardrobes.isEmpty) {
                                return const Center(
                                    child: Text("No wardrobes."));
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: wardrobes.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 32),
                                itemBuilder: (context, index) {
                                  final wardrobe = wardrobes[index];
                                  return WardrobeWidget(
                                    wardrobe: wardrobe,
                                    onDelete: () => deleteWardrobe(wardrobe.id),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    onPressed: () => createWardrobe(context, true),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),

            // Trends tab content
          ],
        ),
      ),
    );
  }
}

class WardrobeWidget extends StatefulWidget {
  final Wardrobe wardrobe;
  final VoidCallback onDelete;

  const WardrobeWidget({
    super.key,
    required this.wardrobe,
    required this.onDelete,
  });

  @override
  State<WardrobeWidget> createState() => _WardrobeWidgetState();
}

class _WardrobeWidgetState extends State<WardrobeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _animationController.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base wardrobe card
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _isSwiping ? 0.0 : 1.0,
              child: SizedBox(
                height: 100 * _heightAnimation.value,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WardrobeDetailsPage(wardrobe: widget.wardrobe),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(64),
                          offset: Offset(0, 0),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.wardrobe.name,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Red overlay that slides over the wardrobe
        Positioned.fill(
            child: Dismissible(
          key: Key('${widget.wardrobe.id}_overlay'),
          direction: DismissDirection.endToStart,
          background: Container(),
          child: Container(),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          movementDuration:
              const Duration(milliseconds: 300), // Make it smoother
          resizeDuration:
              const Duration(milliseconds: 300), // Make resize smoother
          onDismissed: (_) {
            _handleDismiss();
          },
          onResize: () {
            setState(() {
              _isSwiping = true;
            });
          },
          confirmDismiss: (direction) async {
            // This makes the swipe feel more natural
            return true;
          },
        )),
      ],
    );
  }
}

class LikedProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> Products;
  const LikedProductsSection({super.key, required this.Products});

  @override
  Widget build(BuildContext context) {
    if (Products.isEmpty) {
      return Container();
    }

    // Reverse the list so the most recent shoe appears first
    final reversedProducts = List.from(Products.reversed);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  LikedProductsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(64),
              offset: Offset(0, 0),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                    children: [
                      TextSpan(text: '❤ ', style: TextStyle(color: Colors.red)),
                      TextSpan(text: 'Liked Products'),
                    ],
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 28,
                        left: 24,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: 20,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(64),
                                blurRadius: 10,
                                offset: Offset(4, 4),
                              )
                            ]),
                        child: Image.network(
                          reversedProducts[0]['images']?.first['image_url'] ??
                              'assets/images/default_shoe.jpg',
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_shoe.jpg',
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 28,
                        left: 24,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: 20,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(64),
                                blurRadius: 10,
                                offset: Offset(4, 4),
                              )
                            ]),
                        child: Image.network(
                          reversedProducts[1]['images']?.first['image_url'] ??
                              'assets/images/default_shoe.jpg',
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_shoe.jpg',
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 28,
                        left: 24,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: 20,
                        child: Container(
                          width: 70,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(64),
                                    blurRadius: 10,
                                    offset: Offset(4, 4))
                              ]),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(64),
                                blurRadius: 10,
                                offset: Offset(4, 4),
                              )
                            ]),
                        child: Image.network(
                          reversedProducts[2]['images']?.first['image_url'] ??
                              'assets/images/default_shoe.jpg',
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_shoe.jpg',
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("102 saved shoes", style: TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WardrobeDetailsPage extends StatelessWidget {
  final Wardrobe wardrobe;

  const WardrobeDetailsPage({super.key, required this.wardrobe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(wardrobe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit wardrobe page
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Show delete confirmation dialog
            },
          ),
        ],
      ),
      body: WardrobeDetailsContent(wardrobe: wardrobe),
    );
  }
}

class WardrobeDetailsContent extends StatefulWidget {
  final Wardrobe wardrobe;

  const WardrobeDetailsContent({super.key, required this.wardrobe});

  @override
  State<WardrobeDetailsContent> createState() => _WardrobeDetailsContentState();
}

class _WardrobeDetailsContentState extends State<WardrobeDetailsContent> {
  var _products = <CardData>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWardrobeProducts();
  }

  Future<void> _fetchWardrobeProducts() async {
    try {
      String idToken = (await FirebaseAuth.instance.currentUser!.getIdToken())!;
      setState(() => _isLoading = true);

      // First fetch wardrobe details
      final wardrobeResponse = await Dio().get(
        '$wardrobesBaseUrl/${widget.wardrobe.id}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      // Get the product IDs from wardrobe response
      final productIds = wardrobeResponse.data['product_ids'] != null
          ? (wardrobeResponse.data['product_ids'] as List<dynamic>)
              .cast<String>()
          : [];

      // Fetch each product individually
      final products = await Future.wait(
        productIds.map((productId) async {
          final productResponse = await Dio().get(
            '$wardrobesBaseUrl/products/$productId',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );
          return CardData.fromJson(productResponse.data);
        }).toList(),
      );

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load wardrobe products: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchWardrobeProducts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.wardrobe.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${widget.wardrobe.createdAt}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _buildProductGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('No products in this wardrobe'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  product.images[0],
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '\$${product.retailPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Show remove product confirmation dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
