import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/views/widgets/image_360_viewer.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/providers/filters_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductInfoPage extends StatefulWidget {
  final CardData product;

  const ProductInfoPage({super.key, required this.product});

  @override
  State<ProductInfoPage> createState() => _ProductInfoPageState();
}

class _ProductInfoPageState extends State<ProductInfoPage> with TickerProviderStateMixin {
  bool isSaved = false;
  int selectedImageIndex = 0;
  int selectedTabIndex = 0;
  late ScrollController _sizeScrollController;
  int _currentSizePage = 0;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _sizeScrollController = ScrollController();
    _sizeScrollController.addListener(_onSizeScroll);
    
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _tabSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _sizeScrollController.removeListener(_onSizeScroll);
    _sizeScrollController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onSizeScroll() {
    if (_sizeScrollController.hasClients) {
      final position = _sizeScrollController.offset;
      final availableSizes = getAvailableSizes();
      final itemsPerPage = 3;
      final totalPages = (availableSizes.length / itemsPerPage).ceil();
      final itemWidth = 90.0 + 16.0; // card width + margin
      
      if (totalPages > 1) {
        // Calculate current page based on scroll position and item width
        final currentPage = (position / (itemWidth * itemsPerPage)).floor();
        final clampedPage = currentPage.clamp(0, totalPages - 1);
        
        
        if (clampedPage != _currentSizePage) {
          setState(() {
            _currentSizePage = clampedPage;
          });
        }
      }
    }
  }

  void _jumpToSizePage(int page) {
    if (_sizeScrollController.hasClients) {
      final itemsPerPage = 3;
      final itemWidth = 90.0 + 16.0; // card width + margin
      final jumpTo = page * itemsPerPage * itemWidth;
      
      
      _sizeScrollController.animateTo(
        jumpTo,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Get the most relevant lowest ask based on user's preferred sizes
  double? getRelevantLowestAsk() {
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    
    // If user has preferred sizes and product has size-specific pricing
    if (userPreferredSizes.isNotEmpty && widget.product.sizeLowestAsks.isNotEmpty) {
      // Find the lowest ask among user's preferred sizes (ignore 0 values)
      double? lowestAskForUserSizes;
      
      for (double userSize in userPreferredSizes) {
        // Convert user size to string format (e.g., 10.0 -> "10.0")
        String sizeKey = userSize.toString();
        
        // Check if this size exists in the product's size pricing
        if (widget.product.sizeLowestAsks.containsKey(sizeKey)) {
          double sizePrice = widget.product.sizeLowestAsks[sizeKey]!;
          // Only consider prices > 0 (ignore unavailable sizes)
          if (sizePrice > 0 && (lowestAskForUserSizes == null || sizePrice < lowestAskForUserSizes)) {
            lowestAskForUserSizes = sizePrice;
          }
        }
      }
      
      // Return the lowest ask for user's preferred sizes if found
      if (lowestAskForUserSizes != null) {
        return lowestAskForUserSizes;
      }
    }
    
    // Fallback to overall lowest ask if no size-specific match
    return widget.product.lowestAsk;
  }

  // Get size label for the displayed price
  String getSizeLabelForPrice() {
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    
    if (userPreferredSizes.isNotEmpty && widget.product.sizeLowestAsks.isNotEmpty) {
      double? lowestAskForUserSizes;
      String? sizeLabel;
      
      for (double userSize in userPreferredSizes) {
        String sizeKey = userSize.toString();
        if (widget.product.sizeLowestAsks.containsKey(sizeKey)) {
          double sizePrice = widget.product.sizeLowestAsks[sizeKey]!;
          if (sizePrice > 0 && (lowestAskForUserSizes == null || sizePrice < lowestAskForUserSizes)) {
            lowestAskForUserSizes = sizePrice;
            sizeLabel = "Size ${userSize.toStringAsFixed(1)}";
          }
        }
      }
      
      if (sizeLabel != null) {
        return sizeLabel;
      }
    }
    
    return "Lowest Ask";
  }

  // Check if user's preferred sizes are available
  bool areUserSizesAvailable() {
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    
    if (userPreferredSizes.isEmpty || widget.product.sizeLowestAsks.isEmpty) {
      return false;
    }
    
    for (double userSize in userPreferredSizes) {
      String sizeKey = userSize.toString();
      if (widget.product.sizeLowestAsks.containsKey(sizeKey)) {
        double sizePrice = widget.product.sizeLowestAsks[sizeKey]!;
        if (sizePrice > 0) {
          return true; // At least one preferred size is available
        }
      }
    }
    
    return false; // No preferred sizes are available
  }

  // Get all available sizes with pricing
  List<MapEntry<String, double>> getAvailableSizes() {
    List<MapEntry<String, double>> availableSizes = [];
    
    widget.product.sizeLowestAsks.forEach((size, price) {
      if (price > 0) {
        availableSizes.add(MapEntry(size, price));
      }
    });
    
    // Sort by size
    availableSizes.sort((a, b) => double.parse(a.key).compareTo(double.parse(b.key)));
    return availableSizes;
  }

  // Format description with HTML support
  String formatDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'No description available.';
    }
    
    // Replace <br> tags with newlines for better display
    String formatted = description
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n');
    
    // Replace consecutive newlines with single newlines
    while (formatted.contains('\n\n')) {
      formatted = formatted.replaceAll('\n\n', '\n');
    }
    
    return formatted;
  }

  void _selectTab(int index) {
    if (selectedTabIndex != index) {
      setState(() {
        selectedTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image Section with 360 Viewer
          SliverAppBar(
            expandedHeight: 450,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(230),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? AppColors.error : AppColors.onSurface,
                  ),
                  onPressed: () => setState(() => isSaved = !isSaved),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // 360 Viewer with proper spacing
                    Container(
                      height: 450,
                      margin: const EdgeInsets.only(top: 40),
                      child: Image360Viewer(
                        images360: widget.product.images360,
                        height: 450,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Product Information Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandSection(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildSizeAvailabilitySection(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                  const SizedBox(height: 32),
                  _buildBuyButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.product.brand.toUpperCase(),
            style: TextStyle(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Model Name
        Text(
          widget.product.model ?? widget.product.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            height: 1.2,
          ),
        ),
        
        // Product Title (if different from model)
        if (widget.product.model != null && widget.product.model != widget.product.title)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.product.title,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final relevantLowestAsk = getRelevantLowestAsk();
    final sizeLabel = getSizeLabelForPrice();
    final userSizesAvailable = areUserSizesAvailable();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retail Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.product.retailPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sizeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (relevantLowestAsk != null)
                      Text(
                        '\$${relevantLowestAsk.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        'No asks available',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!userSizesAvailable && areUserSizesAvailable() == false)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your preferred sizes are not currently available',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeAvailabilitySection() {
    final availableSizes = getAvailableSizes();
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    
    
    if (availableSizes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No sizes available',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check back later for availability',
                    style: TextStyle(
                      color: AppColors.error.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.straighten, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Sizes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${availableSizes.length} sizes available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${availableSizes.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Horizontal scrolling size carousel
          SizedBox(
            height: 110,
            child: ListView.builder(
              controller: _sizeScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: availableSizes.length,
              itemBuilder: (context, index) {
                final sizeEntry = availableSizes[index];
                final size = sizeEntry.key;
                final price = sizeEntry.value;
                final isUserPreferred = userPreferredSizes.contains(double.tryParse(size));
                
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isUserPreferred ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isUserPreferred 
                            ? AppColors.primary 
                            : AppColors.outline.withOpacity(0.2),
                        width: isUserPreferred ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUserPreferred 
                              ? AppColors.primary.withOpacity(0.25)
                              : AppColors.onSurface.withOpacity(0.08),
                          blurRadius: isUserPreferred ? 16 : 8,
                          offset: const Offset(0, 4),
                          spreadRadius: isUserPreferred ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Size number with larger, bolder text
                              Text(
                                size,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isUserPreferred ? Colors.white : AppColors.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Price with better styling
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUserPreferred 
                                      ? Colors.white.withOpacity(0.2)
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '\$${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isUserPreferred 
                                        ? Colors.white 
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              
                              // User preference indicator
                              if (isUserPreferred) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        size: 9,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Yours',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Scroll indicator dots
          if (availableSizes.length > 3) ...[
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  (availableSizes.length) ~/ 3,
                  (index) => GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _jumpToSizePage(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentSizePage ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentSizePage 
                            ? AppColors.primary 
                            : AppColors.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Additional info if user has preferences
          if (userPreferredSizes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swipe to see all sizes • Blue cards match your preferences',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.info_outline,
            label: 'Details',
            onTap: () {
              _selectTab(1);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.straighten,
            label: 'Specs',
            onTap: () {
              _selectTab(2);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.open_in_new,
            label: 'View Online',
            onTap: () {
              _launchProductUrl();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        // Compact Tab Bar with better visual hierarchy
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildCompactTabButton('Description', 0, Icons.description),
              _buildCompactTabButton('Details', 1, Icons.info_outline),
              _buildCompactTabButton('Specs', 2, Icons.search),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Simple Tab Content
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IndexedStack(
              index: selectedTabIndex,
              children: [
                _buildDescriptionTab(),
                _buildDetailsTab(),
                _buildSpecsTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTabButton(String label, int index, IconData icon) {
    final isSelected = selectedTabIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    final formattedDescription = formatDescription(widget.product.description);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDescription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCompactDetailRow('Category', widget.product.category ?? 'N/A'),
          _buildCompactDetailRow('Secondary Category', widget.product.secondaryCategory ?? 'N/A'),
          _buildCompactDetailRow('SKU', widget.product.sku ?? 'N/A'),
          if (widget.product.colorway.isNotEmpty)
            _buildCompactDetailRow('Colorway', widget.product.colorway.join(', ')),
          if (widget.product.releaseDate != null)
            _buildCompactDetailRow('Release Date', 
              '${widget.product.releaseDate!.day}/${widget.product.releaseDate!.month}/${widget.product.releaseDate!.year}'),
          if (widget.product.upcoming)
            _buildCompactDetailRow('Status', 'Upcoming Release'),
          if (widget.product.trait)
            _buildCompactDetailRow('Special Features', 'Limited Edition'),
        ],
      ),
    );
  }

  Widget _buildSpecsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCompactSpecRow('Brand', widget.product.brand),
          _buildCompactSpecRow('Model', widget.product.model ?? 'N/A'),
          _buildCompactSpecRow('Retail Price', '\$${widget.product.retailPrice.toStringAsFixed(2)}'),
          _buildCompactSpecRow('Available Sizes', '${getAvailableSizes().length} sizes'),
          _buildCompactSpecRow('Images', '${widget.product.images.length} photos'),
          if (widget.product.images360.isNotEmpty)
            _buildCompactSpecRow('360° Views', '${widget.product.images360.length} views'),
          _buildCompactSpecRow('Last Updated', widget.product.updatedAt != null 
            ? '${widget.product.updatedAt!.day}/${widget.product.updatedAt!.month}/${widget.product.updatedAt!.year}'
            : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton() {
    final relevantLowestAsk = getRelevantLowestAsk();
    final sizeLabel = getSizeLabelForPrice();
    final userSizesAvailable = areUserSizesAvailable();
    
    // Determine button text and state
    String buttonText;
    bool isEnabled = true;
    
    if (relevantLowestAsk != null) {
      buttonText = 'Buy Now';
    } else if (userSizesAvailable == false) {
      buttonText = 'Sizes Not Available';
      isEnabled = false;
    } else {
      buttonText = 'Buy Now';
    }
    
    return GestureDetector(
      onTap: isEnabled ? _launchProductUrl : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled 
                ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
                : [AppColors.outline, AppColors.outline.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buttonText,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : AppColors.onSurface.withOpacity(0.6),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (relevantLowestAsk != null) ...[
                  Row(
                    children: [
                      Text(
                        '\$${relevantLowestAsk.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isEnabled ? Colors.white : AppColors.onSurface.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sizeLabel,
                        style: TextStyle(
                          color: isEnabled ? Colors.white.withOpacity(0.8) : AppColors.onSurface.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'View Online',
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withOpacity(0.8) : AppColors.onSurface.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white.withOpacity(0.2) : AppColors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: isEnabled ? Colors.white : AppColors.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchProductUrl() async {
    final url = widget.product.link;
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open product link')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid product link')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product link available')),
      );
    }
  }
} 