import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/views/widgets/image_360_viewer.dart';

class ProductInfoPage extends StatelessWidget {
  final CardData product;

  const ProductInfoPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product Details',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images - 360 viewer if available, otherwise regular gallery
            if (product.images360.isNotEmpty && product.images360[0] != "null")
              Padding(
                padding: const EdgeInsets.all(16),
                child: Image360Viewer(
                  images360: product.images360,
                  height: 350,
                  width: MediaQuery.of(context).size.width - 32,
                ),
              )
            else if (product.images.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(64),
                            blurRadius: 20,
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surface,
                              child: Icon(
                                Icons.error,
                                size: 64,
                                color: AppColors.onSurface,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand and Model
                  Text(
                    product.brand ?? 'Unknown Brand',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.model ?? 'Unknown Model',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        '\$${product.retailPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Retail Price',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  if (product.description != null && product.description!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurface.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  // Product Details
                  _buildDetailSection('Category', product.category ?? 'N/A'),
                  _buildDetailSection('Secondary Category', product.secondaryCategory ?? 'N/A'),
                  _buildDetailSection('SKU', product.sku ?? 'N/A'),
                  
                  // Colorway
                  if (product.colorway.isNotEmpty)
                    _buildDetailSection('Colorway', product.colorway.join(', ')),
                  
                  // Release Date
                  if (product.releaseDate != null)
                    _buildDetailSection('Release Date', 
                      '${product.releaseDate!.day}/${product.releaseDate!.month}/${product.releaseDate!.year}'),
                  
                  // Updated At
                  if (product.updatedAt != null)
                    _buildDetailSection('Last Updated', 
                      '${product.updatedAt!.day}/${product.updatedAt!.month}/${product.updatedAt!.year}'),
                  
                  // Special Features
                  if (product.trait)
                    _buildDetailSection('Special Features', 'Limited Edition'),
                  
                  if (product.upcoming)
                    _buildDetailSection('Status', 'Upcoming Release'),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement purchase functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Purchase functionality coming soon!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Purchase',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement save to wishlist functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to wishlist!'),
                                backgroundColor: AppColors.tertiary,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.tertiary,
                            side: BorderSide(color: AppColors.tertiary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
} 