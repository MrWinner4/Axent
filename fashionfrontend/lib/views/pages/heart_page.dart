import 'dart:async';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trends_page.dart';
import 'package:fashionfrontend/app_colors.dart';

// API Configuration
class ApiConfig {
  static const String likedProductsBaseUrl = 'https://axentbackend.onrender.com/preferences';
  static const String wardrobesBaseUrl = 'https://axentbackend.onrender.com/wardrobes';
}

// Service class for API operations
class HeartPageService {
  static final Dio _dio = Dio();

  static Future<String> _getIdToken() async {
    return (await FirebaseAuth.instance.currentUser!.getIdToken())!;
  }

  static Future<String> _getUserId() async {
    final decodedToken = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    final userId = decodedToken.claims?['user_id'];
    if (userId == null) {
      throw Exception('User ID not found in token');
    }
    return userId;
  }

  static Future<List<dynamic>> fetchLikedProducts() async {
    final idToken = await _getIdToken();
    final response = await _dio.get(
      '${ApiConfig.likedProductsBaseUrl}/liked_products/',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
    return response.data;
  }

  static Future<List<Wardrobe>> fetchWardrobes() async {
    final idToken = await _getIdToken();
    final userId = await _getUserId();
    
    final response = await _dio.get(
      '${ApiConfig.wardrobesBaseUrl}/user/',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      queryParameters: {'firebase_uid': userId},
    );

    if (response.data == null) return [];
    
    try {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Wardrobe.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> createWardrobe(String name) async {
    final idToken = await _getIdToken();
    final userId = await _getUserId();
    
    await _dio.post(
      '${ApiConfig.wardrobesBaseUrl}/',
      data: {'name': name, 'user': userId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  static Future<void> deleteWardrobe(String wardrobeId) async {
    final idToken = await _getIdToken();
    await _dio.delete(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId/',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
  }

  static Future<void> addToWardrobe(String wardrobeId, String productId) async {
    final idToken = await _getIdToken();
    await _dio.post(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId/add_item/',
      data: {'product_id': productId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  static Future<void> removeFromWardrobe(String wardrobeId, String productId) async {
    final idToken = await _getIdToken();
    await _dio.post(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId/remove_item/',
      data: {'product_id': productId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}

// Main Heart Page
class HeartPage extends StatefulWidget {
  const HeartPage({super.key});

  @override
  HeartPageState createState() => HeartPageState();
}

class HeartPageState extends State<HeartPage> with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<dynamic>> _productsNotifier = ValueNotifier([]);
  final ValueNotifier<List<Wardrobe>> _wardrobesNotifier = ValueNotifier([]);
  bool _isLoading = true;
  bool _isWardrobesLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _productsNotifier.dispose();
    _wardrobesNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchLikedProducts(),
      _fetchWardrobes(),
    ]);
  }

  Future<void> _fetchLikedProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await HeartPageService.fetchLikedProducts();
      if (mounted) {
        _productsNotifier.value = products;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching liked products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void refreshLikedProducts() {
    setState(() => _isLoading = true);
    _fetchLikedProducts();
  }

  Future<void> _fetchWardrobes() async {
    try {
      setState(() => _isWardrobesLoading = true);
      final wardrobes = await HeartPageService.fetchWardrobes();
      if (mounted) {
        _wardrobesNotifier.value = wardrobes;
        setState(() => _isWardrobesLoading = false);
      }
    } catch (e) {
      print('Error fetching wardrobes: $e');
      if (mounted) {
        setState(() => _isWardrobesLoading = false);
        _showErrorSnackBar('Failed to load wardrobes: ${e.toString()}');
      }
    }
  }

  Future<void> _createWardrobe() async {
    try {
      final name = await _showCreateWardrobeDialog();
      if (name == null || name.isEmpty) return;

      await _showLoadingDialog('Creating wardrobe...');
      await HeartPageService.createWardrobe(name);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSuccessSnackBar('Wardrobe created successfully: $name');
        _fetchWardrobes();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('Failed to create wardrobe: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteWardrobe(String wardrobeId) async {
    try {
      await HeartPageService.deleteWardrobe(wardrobeId);
      if (mounted) {
        _fetchWardrobes();
      }
    } catch (e) {
      print('Error deleting wardrobe: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to delete wardrobe: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.tertiary),
    );
  }

  Future<void> _showLoadingDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      key: const PageStorageKey('heart'),
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(text: 'Trends'),
              Tab(text: 'Wardrobes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const TrendsPage(),
            _buildWardrobesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobesTab() {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _PageTitle(),
                  const SizedBox(height: 40),
                  _buildLikedProductsSection(),
                  const SizedBox(height: 40),
                  _buildWardrobesList(),
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
            onPressed: _createWardrobe,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildLikedProductsSection() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _productsNotifier,
      builder: (context, products, _) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (products.isEmpty) {
          return const Center(child: Text("No liked products."));
        }
        
        final recentProducts = products.length >= 3
            ? products.sublist(products.length - 3)
            : products;
            
        return LikedProductsSection(
          products: recentProducts,
        );
      },
    );
  }

  Widget _buildWardrobesList() {
    return ValueListenableBuilder<List<Wardrobe>>(
      valueListenable: _wardrobesNotifier,
      builder: (context, wardrobes, _) {
        if (_isWardrobesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (wardrobes.isEmpty) {
          return const Center(child: Text("No wardrobes."));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: wardrobes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 32),
          itemBuilder: (context, index) {
            final wardrobe = wardrobes[index];
            return WardrobeCard(
              wardrobe: wardrobe,
              onDelete: () => _deleteWardrobe(wardrobe.id),
            );
          },
        );
      },
    );
  }
}

// UI Components
class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Your Wardrobes",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class LikedProductsSection extends StatelessWidget {
  final List<dynamic> products;
  
  const LikedProductsSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final reversedProducts = List.from(products.reversed);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LikedProductsPage(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withAlpha(64),
              offset: const Offset(0, 0),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            _buildProductStack(reversedProducts),
            const SizedBox(height: 8),
            _buildProductCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
            children: [
              const TextSpan(text: '❤ ', style: TextStyle(color: AppColors.error)),
              const TextSpan(text: 'Liked Products'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductStack(List<dynamic> products) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        products.length.clamp(0, 3),
        (index) => _ProductStackItem(product: products[index] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildProductCount() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text("102 saved shoes", style: TextStyle(color: AppColors.secondary)),
      ],
    );
  }
}

class _ProductStackItem extends StatelessWidget {
  final Map<String, dynamic> product;
  
  const _ProductStackItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background layers for stack effect
          for (int i = 2; i >= 0; i--)
            Positioned(
              top: 28 - (i * 4),
              left: 24 - (i * 4),
              child: Container(
                width: 70,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withAlpha(64),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
              ),
            ),
          // Main product image
          Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface, width: 4.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withAlpha(64),
                  blurRadius: 10,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Image.network(
              product['images']?.first['image_url'] ?? 'assets/images/default_shoe.jpg',
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
    );
  }
}

class WardrobeCard extends StatefulWidget {
  final Wardrobe wardrobe;
  final VoidCallback onDelete;

  const WardrobeCard({
    super.key,
    required this.wardrobe,
    required this.onDelete,
  });

  @override
  State<WardrobeCard> createState() => _WardrobeCardState();
}

class _WardrobeCardState extends State<WardrobeCard>
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
        _buildWardrobeContent(),
        _buildDismissibleOverlay(),
      ],
    );
  }

  Widget _buildWardrobeContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _isSwiping ? 0.0 : 1.0,
          child: SizedBox(
            height: 100 * _heightAnimation.value,
            child: GestureDetector(
              onTap: () => _navigateToWardrobeDetails(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withAlpha(64),
                      offset: const Offset(0, 0),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.wardrobe.name,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
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
    );
  }

  Widget _buildDismissibleOverlay() {
    return Positioned.fill(
      child: Dismissible(
        key: Key('${widget.wardrobe.id}_overlay'),
        direction: DismissDirection.endToStart,
        background: Container(),
        child: Container(),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: AppColors.surface),
        ),
        movementDuration: const Duration(milliseconds: 300),
        resizeDuration: const Duration(milliseconds: 300),
        onDismissed: (_) => _handleDismiss(),
        onResize: () => setState(() => _isSwiping = true),
        confirmDismiss: (direction) async => true,
      ),
    );
  }

  void _navigateToWardrobeDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WardrobeDetailsPage(wardrobe: widget.wardrobe),
      ),
    );
  }
}

// Wardrobe Details Page
class WardrobeDetailsPage extends StatelessWidget {
  final Wardrobe wardrobe;

  const WardrobeDetailsPage({super.key, required this.wardrobe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(wardrobe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit wardrobe page
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Show delete confirmation dialog
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
  List<CardData> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWardrobeProducts();
  }

  Future<void> _fetchWardrobeProducts() async {
    try {
      setState(() => _isLoading = true);

      final idToken = await HeartPageService._getIdToken();
      
      // Fetch wardrobe details
      final wardrobeResponse = await HeartPageService._dio.get(
        '${ApiConfig.wardrobesBaseUrl}/${widget.wardrobe.id}',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      final productIds = wardrobeResponse.data['product_ids'] != null
          ? (wardrobeResponse.data['product_ids'] as List<dynamic>).cast<String>()
          : [];

      // Fetch each product individually
      final products = await Future.wait(
        productIds.map((productId) async {
          final productResponse = await HeartPageService._dio.get(
            '${ApiConfig.wardrobesBaseUrl}/products/$productId',
            options: Options(headers: {'Authorization': 'Bearer $idToken'}),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wardrobe products: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No products in this wardrobe'));
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
                  // TODO: Show remove product confirmation dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper functions
Future<String?> _showCreateWardrobeDialog() {
  return showDialog<String>(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final controller = TextEditingController();

      return AlertDialog(
        title: const Text('Create New Wardrobe'),
        content: TextField(
          autofocus: true,
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter wardrobe name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}

// Global navigator key for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
