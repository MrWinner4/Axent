import 'dart:async';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/views/pages/liked_products_page.dart';
import 'package:fashionfrontend/views/widgets/liked_products_carousel.dart';
import 'package:fashionfrontend/providers/liked_products_provider.dart';
import 'package:fashionfrontend/providers/wardrobes_provider.dart';
import 'package:fashionfrontend/data/liked_products_service.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'trends_page.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/views/pages/wardrobes_page.dart';
import 'package:fashionfrontend/views/pages/wardrobe_detail_page.dart'
    as detail;

// API Configuration
class ApiConfig {
  static const String likedProductsBaseUrl =
      'https://axentbackend.onrender.com/preferences';
  static const String wardrobesBaseUrl =
      'https://axentbackend.onrender.com/wardrobes';
}

// Service class for API operations
class HeartPageService {
  static final Dio _dio = Dio();

  static Future<String> _getIdToken() async {
    return (await FirebaseAuth.instance.currentUser!.getIdToken())!;
  }

  static Future<String> _getUserId() async {
    final decodedToken =
        await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    final userId = decodedToken.claims?['user_id'];
    if (userId == null) {
      throw Exception('User ID not found in token');
    }
    return userId;
  }

  static Future<List<dynamic>> fetchLikedProducts(
      {int page = 1, int pageSize = 20}) async {
    final idToken = await _getIdToken();
    final response = await _dio.get(
      '${ApiConfig.likedProductsBaseUrl}/liked_products/',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      queryParameters: {'page': page, 'page_size': pageSize},
    );

    // Handle the new paginated response format
    if (response.data is Map<String, dynamic> &&
        response.data['products'] != null) {
      return response.data['products'] as List<dynamic>;
    }

    // Fallback for old format
    return response.data as List<dynamic>;
  }

  static Future<List<dynamic>> fetchAllLikedProducts() async {
    final idToken = await _getIdToken();
    final response = await _dio.get(
      '${ApiConfig.likedProductsBaseUrl}/liked_products/',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      queryParameters: {
        'page': 1,
        'page_size': 1000
      }, // Large page size to get all products
    );

    // Handle the new paginated response format
    if (response.data is Map<String, dynamic> &&
        response.data['products'] != null) {
      return response.data['products'] as List<dynamic>;
    }

    // Fallback for old format
    return response.data as List<dynamic>;
  }

  static Future<List<Wardrobe>> fetchWardrobes() async {
    final idToken = await _getIdToken();
    final userId = await _getUserId();

    final response = await _dio.get(
      '${ApiConfig.wardrobesBaseUrl}/user',
      options: Options(
        headers: {'Authorization': 'Bearer $idToken'},
        followRedirects: true,
        validateStatus: (status) => status! < 500,
      ),
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
      ApiConfig.wardrobesBaseUrl,
      data: {'name': name, 'user': userId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        followRedirects: true,
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  static Future<void> deleteWardrobe(String wardrobeId) async {
    final idToken = await _getIdToken();
    await _dio.delete(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId',
      options: Options(
        headers: {'Authorization': 'Bearer $idToken'},
        followRedirects: true,
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  static Future<void> addToWardrobe(String wardrobeId, String productId) async {
    final idToken = await _getIdToken();
    await _dio.post(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId/add_item',
      data: {'product_id': productId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        followRedirects: true,
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  static Future<void> removeFromWardrobe(
      String wardrobeId, String productId) async {
    final idToken = await _getIdToken();
    await _dio.post(
      '${ApiConfig.wardrobesBaseUrl}/$wardrobeId/remove_item',
      data: {'product_id': productId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        followRedirects: true,
        validateStatus: (status) => status! < 500,
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

class HeartPageState extends State<HeartPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _initializeServices() async {
    // Set up the API fetch function for the service
    LikedProductsService.setAPIFetchFunction(
        HeartPageService.fetchAllLikedProducts);

    // Initialize the liked products service
    final likedProductsProvider =
        Provider.of<LikedProductsProvider>(context, listen: false);
    await likedProductsProvider.initialize();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      key: const PageStorageKey('heart'),
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: TabBar(
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: -0.2,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.25),
              letterSpacing: -0.2,
              fontFamily: 'Inter',
            ),
            tabs: [
              Tab(text: 'Wardrobes'),
              Tab(text: 'Trends'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildWardrobesTab(),
            const TrendsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobesTab() {
    return Consumer<WardrobesProvider>(
      builder: (context, wardrobesProvider, child) {
        print(
            'Building wardrobes tab. Loading: ${wardrobesProvider.isLoading}, Count: ${wardrobesProvider.wardrobes.length}');

        if (wardrobesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        print(
            'Showing simplified wardrobes view with ${wardrobesProvider.wardrobes.length} wardrobes');
        return _buildSimplifiedWardrobesView(wardrobesProvider);
      },
    );
  }

  Widget _buildSimplifiedWardrobesView(WardrobesProvider wardrobesProvider) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
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
              _buildWardrobesSearchSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createWardrobe(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLikedProductsSection() {
    return Consumer<LikedProductsProvider>(
      builder: (context, provider, child) {
        return LikedProductsCarousel(
          likedProducts: provider.likedProducts,
          onRefresh: () => provider.refreshLikedProducts(),
          isLoading: provider.isLoading,
        );
      },
    );
  }

  Widget _buildWardrobesSearchSection() {
    return Consumer<WardrobesProvider>(
      builder: (context, wardrobesProvider, child) {
        final filteredWardrobes = _searchQuery.isEmpty
            ? wardrobesProvider.wardrobes
            : wardrobesProvider.wardrobes.where((wardrobe) {
                return wardrobe.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Wardrobes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildWardrobesList(filteredWardrobes),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search your wardrobes...',
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(
          color: AppColors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWardrobesList(List<Wardrobe> wardrobes) {
    if (wardrobes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No wardrobes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first wardrobe to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          wardrobes.map((wardrobe) => _buildWardrobeCard(wardrobe)).toList(),
    );
  }

  Widget _buildWardrobeCard(Wardrobe wardrobe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: Text(
            wardrobe.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: Text(
            '${wardrobe.productIds?.length ?? 0} items',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.onSurface.withValues(alpha: 0.4),
            size: 16,
          ),
          onTap: () {
            // Navigate to wardrobe details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    detail.WardrobeDetailsPage(wardrobe: wardrobe),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createWardrobe() async {
    final name = await _showCreateWardrobeDialog();
    if (name != null && name.isNotEmpty) {
      print('Creating wardrobe with name: $name');
      final wardrobesProvider =
          Provider.of<WardrobesProvider>(context, listen: false);
      final success = await wardrobesProvider.createWardrobe(name);
      print('Wardrobe creation result: $success');
      if (success) {
        _showSuccessSnackBar('Wardrobe created successfully: $name');
        print('Success message shown');
      } else {
        _showErrorSnackBar('Failed to create wardrobe');
        print('Error message shown');
      }
    } else {
      print('Wardrobe creation cancelled or empty name');
    }
  }

  Future<String?> _showCreateWardrobeDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Wardrobe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Wardrobe Name',
            hintText: 'Enter wardrobe name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// UI Components
class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Wardrobes",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.bold,
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
        builder: (context) =>
            detail.WardrobeDetailsPage(wardrobe: widget.wardrobe),
      ),
    );
  }
}

// Global navigator key for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
