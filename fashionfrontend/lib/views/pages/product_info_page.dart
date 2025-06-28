import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/views/widgets/image_360_viewer.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/providers/filters_provider.dart';

class ProductInfoPage extends StatefulWidget {
  final CardData product;

  const ProductInfoPage({super.key, required this.product});

  @override
  State<ProductInfoPage> createState() => _ProductInfoPageState();
}

class _ProductInfoPageState extends State<ProductInfoPage> {
  bool isSaved = false;
  int selectedImageIndex = 0;

  // Get the most relevant lowest ask based on user's preferred sizes
  double? getRelevantLowestAsk() {
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    
    // If user has preferred sizes and product has size-specific pricing
    if (userPreferredSizes.isNotEmpty && widget.product.sizeLowestAsks.isNotEmpty) {
      // Find the lowest ask among user's preferred sizes
      double? lowestAskForUserSizes;
      
      for (double userSize in userPreferredSizes) {
        // Convert user size to string format (e.g., 10.0 -> "10.0")
        String sizeKey = userSize.toString();
        
        // Check if this size exists in the product's size pricing
        if (widget.product.sizeLowestAsks.containsKey(sizeKey)) {
          double sizePrice = widget.product.sizeLowestAsks[sizeKey]!;
          if (sizePrice > 0) {
            if (lowestAskForUserSizes == null || sizePrice < lowestAskForUserSizes) {
              lowestAskForUserSizes = sizePrice;
            }
          }
        }
      }
      
      if (lowestAskForUserSizes != null) {
        return lowestAskForUserSizes;
      }
    }
    
    // Fallback to overall lowest ask if no size-specific match
    return widget.product.lowestAsk;
  }

  // Get the size label for the displayed price
  String? getSizeLabelForPrice() {
    final filtersProvider = Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;
    final relevantPrice = getRelevantLowestAsk();
    
    if (userPreferredSizes.isNotEmpty && widget.product.sizeLowestAsks.isNotEmpty) {
      // Find which user size corresponds to the displayed price
      for (double userSize in userPreferredSizes) {
        String sizeKey = userSize.toString();
        if (widget.product.sizeLowestAsks.containsKey(sizeKey)) {
          double sizePrice = widget.product.sizeLowestAsks[sizeKey]!;
          if (sizePrice == relevantPrice) {
            return sizeKey;
          }
        }
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image Section with 360 Viewer
          SliverAppBar(
            expandedHeight: 400, // Increased from 400 to give more space
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
                      height: 400, // Increased height for 360 viewer
                      margin: const EdgeInsets.only(top: 40), // Reduced top margin to ensure text visibility
                      child: Image360Viewer(
                        images360: widget.product.images360,
                        height: 400,
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
                  _buildActionButtons(),
                  const SizedBox(height: 32),
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
                        color: AppColors.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.product.retailPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (relevantLowestAsk != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        sizeLabel != null 
                            ? 'Lowest Ask (Size $sizeLabel)'
                            : 'Lowest Ask',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${relevantLowestAsk.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.product.trait)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.onTertiaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Limited Edition',
                    style: TextStyle(
                      color: AppColors.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.compare_arrows,
            label: 'Compare',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compare functionality coming soon!')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.info_outline,
            label: 'Details',
            onTap: () {
              _showProductDetailsModal(context);
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
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurface.withOpacity(0.6),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Description'),
                Tab(text: 'Details'),
                Tab(text: 'Specs'),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            height: 300,
            child: TabBarView(
              children: [
                _buildDescriptionTab(),
                _buildDetailsTab(),
                _buildSpecsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          widget.product.description ?? 'No description available.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurface.withOpacity(0.8),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildDetailRow('Category', widget.product.category ?? 'N/A'),
            _buildDetailRow('Secondary Category', widget.product.secondaryCategory ?? 'N/A'),
            _buildDetailRow('SKU', widget.product.sku ?? 'N/A'),
            if (widget.product.colorway.isNotEmpty)
              _buildDetailRow('Colorway', widget.product.colorway.join(', ')),
            if (widget.product.releaseDate != null)
              _buildDetailRow('Release Date', 
                '${widget.product.releaseDate!.day}/${widget.product.releaseDate!.month}/${widget.product.releaseDate!.year}'),
            if (widget.product.upcoming)
              _buildDetailRow('Status', 'Upcoming Release'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSpecRow('Brand', widget.product.brand),
            _buildSpecRow('Model', widget.product.model ?? 'N/A'),
            _buildSpecRow('Price', '\$${widget.product.retailPrice.toStringAsFixed(2)}'),
            _buildSpecRow('Images', '${widget.product.images.length} photos'),
            if (widget.product.images360.isNotEmpty)
              _buildSpecRow('360° Views', '${widget.product.images360.length} views'),
            _buildSpecRow('Last Updated', widget.product.updatedAt != null 
              ? '${widget.product.updatedAt!.day}/${widget.product.updatedAt!.month}/${widget.product.updatedAt!.year}'
              : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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
    
    // Determine display price: size-specific lowest ask > overall lowest ask > retail
    double displayPrice = widget.product.retailPrice;
    if (relevantLowestAsk != null) {
      displayPrice = relevantLowestAsk;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sizeLabel != null ? 'Buy Size $sizeLabel' : 'Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Brand', widget.product.brand),
                    _buildDetailRow('Model', widget.product.model ?? 'N/A'),
                    _buildDetailRow('Category', widget.product.category ?? 'N/A'),
                    _buildDetailRow('SKU', widget.product.sku ?? 'N/A'),
                    if (widget.product.colorway.isNotEmpty)
                      _buildDetailRow('Colorway', widget.product.colorway.join(', ')),
                    if (widget.product.releaseDate != null)
                      _buildDetailRow('Release Date', 
                        '${widget.product.releaseDate!.day}/${widget.product.releaseDate!.month}/${widget.product.releaseDate!.year}'),
                    if (widget.product.updatedAt != null)
                      _buildDetailRow('Last Updated', 
                        '${widget.product.updatedAt!.day}/${widget.product.updatedAt!.month}/${widget.product.updatedAt!.year}'),
                    if (widget.product.trait)
                      _buildDetailRow('Special Features', 'Limited Edition'),
                    if (widget.product.upcoming)
                      _buildDetailRow('Status', 'Upcoming Release'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 