import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fashionfrontend/app_colors.dart';

class Image360Viewer extends StatefulWidget {
  final List<String> images360;
  final double height;
  final double width;

  const Image360Viewer({
    super.key,
    required this.images360,
    this.height = 300,
    this.width = double.infinity,
  });

  @override
  State<Image360Viewer> createState() => _Image360ViewerState();
}

class _Image360ViewerState extends State<Image360Viewer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  int _currentIndex = 0;
  bool _isAnimating = false;
  double _dragStartX = 0;
  double _dragDistance = 0;
  bool _isDraggingProgressBar = false;
  
  // Advanced image caching system
  Map<int, ui.Image?> _imageCache = {};
  Map<int, Completer<ui.Image>> _imageCompleters = {};
  bool _allImagesLoaded = false;
  int _loadedImageCount = 0;
  bool _isLoading = true;
  
  // Animation settings - increased sensitivity
  static const double sensitivity = 1.5;

  // Get the limited list of images (max 36)
  List<String> get _limitedImages {
    return widget.images360.take(36).toList();
  }
  
  // Get the actual number of images to use
  int get _totalImages => _limitedImages.length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Initialize image completers for limited images only
    for (int i = 0; i < _totalImages; i++) {
      _imageCompleters[i] = Completer<ui.Image>();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start loading all images when dependencies are available
    if (!_allImagesLoaded) {
      _loadAllImages();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllImages() async {
    final totalImages = _totalImages; // Use limited count
    
    // Create a list of futures for all image loading operations
    List<Future<void>> loadFutures = [];
    
    for (int i = 0; i < totalImages; i++) {
      loadFutures.add(_loadSingleImage(i));
    }
    
    // Wait for all images to load
    await Future.wait(loadFutures);
    
    if (mounted) {
      setState(() {
        _allImagesLoaded = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSingleImage(int index) async {
    try {
      // Create image provider using limited images
      final imageProvider = NetworkImage(_limitedImages[index]);
      
      // Load the image using ImageStream
      final completer = Completer<ui.Image>();
      final stream = imageProvider.resolve(ImageConfiguration.empty);
      
      stream.addListener(ImageStreamListener((info, _) {
        completer.complete(info.image);
      }, onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }));
      
      // Wait for the image to load
      final image = await completer.future;
      
      if (mounted) {
        setState(() {
          _imageCache[index] = image;
          _loadedImageCount++;
        });
      }
    } catch (e) {
      // Handle any errors during loading
      if (mounted) {
        setState(() {
          _loadedImageCount++;
        });
      }
    }
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragDistance = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    
    _dragDistance += details.delta.dx;
    
    // Calculate how many images to move based on drag distance - reversed direction
    double imageWidth = widget.width;
    double pixelsPerImage = imageWidth / _totalImages; // Use limited count
    int imagesToMove = (-_dragDistance / pixelsPerImage * sensitivity).round();
    
    if (imagesToMove.abs() >= 1) {
      int newIndex = (_currentIndex + imagesToMove) % _totalImages; // Use limited count
      if (newIndex < 0) newIndex = _totalImages + newIndex;
      
      setState(() {
        _currentIndex = newIndex;
      });
      
      _dragDistance = 0;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    // Optional: Add momentum scrolling here if desired
  }

  void _onProgressBarDragStart(DragStartDetails details) {
    setState(() {
      _isDraggingProgressBar = true;
    });
  }

  void _onProgressBarDragUpdate(DragUpdateDetails details, RenderBox renderBox) {
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final progressBarWidth = renderBox.size.width;
    final progress = (localPosition.dx / progressBarWidth).clamp(0.0, 1.0);
    
    final newIndex = (progress * (_totalImages - 1)).round(); // Use limited count
    
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _onProgressBarDragEnd(DragEndDetails details) {
    setState(() {
      _isDraggingProgressBar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(64),
            blurRadius: 20,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 360 Image Viewer - Static image that changes based on index
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Container(
                width: widget.width,
                height: widget.height,
                child: _buildImageWidget(),
              ),
            ),
          ),
          
          // Skinny Progress Bar with Circular Indicator
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onPanStart: _onProgressBarDragStart,
              onPanUpdate: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                _onProgressBarDragUpdate(details, renderBox);
              },
              onPanEnd: _onProgressBarDragEnd,
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppColors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    // Progress Bar Fill
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_currentIndex + 1) / _totalImages,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Circular Progress Indicator
                    Positioned(
                      left: ((_currentIndex + 1) / _totalImages) * (widget.width - 32 - 80) - 8,
                      top: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(64),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Instructions (only show when not dragging progress bar and images are loaded)
          if (!_isDraggingProgressBar && _allImagesLoaded)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(32),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Swipe to rotate 360°',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_isLoading) {
      return Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: _loadedImageCount / _totalImages,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading 360° view...\n${_loadedImageCount}/${_totalImages}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if current image is loaded
    final currentImage = _imageCache[_currentIndex];
    
    if (currentImage != null) {
      // Use RawImage for better performance and no white spots
      return RawImage(
        image: currentImage,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else {
      // Fallback to NetworkImage if cached image is not available
      return Image.network(
        _limitedImages[_currentIndex],
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surface,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
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
      );
    }
  }
} 