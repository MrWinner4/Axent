import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fashionfrontend/app_colors.dart';
import 'package:fashionfrontend/models/wardrobe_model.dart';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/providers/wardrobes_provider.dart';

class AddToWardrobeWidget extends StatefulWidget {
  final CardData product;

  const AddToWardrobeWidget({
    super.key,
    required this.product,
  });

  @override
  State<AddToWardrobeWidget> createState() => _AddToWardrobeWidgetState();
}

class _AddToWardrobeWidgetState extends State<AddToWardrobeWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobesProvider>(
      builder: (context, wardrobesProvider, child) {
        final wardrobes = wardrobesProvider.wardrobes;
        final containingWardrobes = wardrobesProvider.getWardrobesContainingProduct(widget.product.id);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add to Wardrobe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Wardrobes List
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: wardrobes.isEmpty
                  ? _buildEmptyWardrobesState()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: wardrobes.length,
                      itemBuilder: (context, index) {
                        final wardrobe = wardrobes[index];
                        final isInWardrobe = containingWardrobes.any((w) => w.id == wardrobe.id);
                        
                        return _buildWardrobeItem(
                          wardrobe,
                          isInWardrobe,
                          wardrobesProvider,
                        );
                      },
                    ),
            ),

            // Create New Wardrobe Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _createNewWardrobe(context, wardrobesProvider),
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Creating...' : 'Create New Wardrobe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyWardrobesState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
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
            'Create your first wardrobe to organize your style',
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

  Widget _buildWardrobeItem(
    Wardrobe wardrobe,
    bool isInWardrobe,
    WardrobesProvider wardrobesProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInWardrobe
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isInWardrobe
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isInWardrobe ? Icons.folder_rounded : Icons.folder_outlined,
            color: isInWardrobe ? AppColors.primary : Colors.grey.withValues(alpha: 0.6),
            size: 20,
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
          '${wardrobe.productIds.length} items',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInWardrobe
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isInWardrobe ? 'Remove' : 'Add',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isInWardrobe ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
        onTap: _isLoading
            ? null
            : () => _toggleWardrobe(wardrobe, isInWardrobe, wardrobesProvider),
      ),
    );
  }

  Future<void> _toggleWardrobe(
    Wardrobe wardrobe,
    bool isInWardrobe,
    WardrobesProvider wardrobesProvider,
  ) async {
    setState(() => _isLoading = true);

    try {
      bool success;
      if (isInWardrobe) {
        success = await wardrobesProvider.removeFromWardrobe(wardrobe.id, widget.product.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from ${wardrobe.name}'),
              backgroundColor: AppColors.tertiary,
            ),
          );
        }
      } else {
        success = await wardrobesProvider.addToWardrobe(wardrobe.id, widget.product.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to ${wardrobe.name}'),
              backgroundColor: AppColors.tertiary,
            ),
          );
        }
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isInWardrobe ? 'remove from' : 'add to'} ${wardrobe.name}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNewWardrobe(BuildContext context, WardrobesProvider wardrobesProvider) async {
    setState(() => _isLoading = true);

    try {
      final name = await _showCreateWardrobeDialog();
      if (name != null && name.isNotEmpty) {
        final success = await wardrobesProvider.createWardrobe(name);
        if (success && mounted) {
          // Automatically add the product to the new wardrobe
          final newWardrobe = wardrobesProvider.wardrobes.last;
          await wardrobesProvider.addToWardrobe(newWardrobe.id, widget.product.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created wardrobe "$name" and added product'),
              backgroundColor: AppColors.tertiary,
            ),
          );
          
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create wardrobe'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showCreateWardrobeDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create New Wardrobe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Wardrobe Name',
            hintText: 'Enter wardrobe name...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
} 