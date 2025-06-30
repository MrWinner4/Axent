import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/providers/filters_provider.dart';
import 'package:fashionfrontend/providers/liked_products_provider.dart';
import 'package:fashionfrontend/views/pages/home_page.dart';
import 'package:fashionfrontend/views/pages/product_info_page.dart';
import 'package:fashionfrontend/views/widgets/add_to_wardrobe_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:fashionfrontend/app_colors.dart';

//! FIX: I need to have an "updateCardWidgets()" method along with some widgets for current and next card and only call that method to update the cards and instead call buildcard there
class SwipeableCard extends StatefulWidget {
  final SwipeableCardController controller;

  const SwipeableCard({super.key, required this.controller});

  @override
  State<SwipeableCard> createState() => SwipeableCardState();
}

class SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final int CARDSTACKSIZE = 5; // How many cards to load at once
  //Position for Card
  double _left = 0;
  double _top = 0;
  //Rotation angle for card
  double rotationAngle = 0.0;
  //Opacity of red and green boxes to the side of the screen
  double redOpacity = 0.0;
  double greenOpacity = 0.0;
  final double sittingOpacity = 0.0;
  //Card dimensions
  late double cardWidth;
  late double cardHeight;
  late double usableScreenHeight;
  //Threshold for swipe, need to go this far to trigger a swipe
  late double threshold;
  //Is the card Loaded?
  bool _isLoaded = false;
  // If true, the next card animates (pops up) from behind
  bool _popUp = false;
  // Center coordinates for the card.
  late double centerLeft = 0;
  late double centerTop = 0;
  //For caching current card
  Widget? _currentCardWidget;
  //For caching next card
  Widget? _nextCardWidget;

  double undoLeft = 0;
  bool isUndoing = false;

  bool isButtonAnimating = false;

  late AnimationController undoController;
  late Animation<double> undoPositionAnimation;

  late AnimationController transitionController;
  late Animation<double> scaleAnimation;
  late Animation<double> blurAnimation;

  Random randnum = Random();

  int range = 3;

  CardData? _currentCardData;
  CardData? _nextCardData;

  late CardQueueModel _cardQueue;
  late FiltersProvider _filtersProvider;

  bool isValidImage(String? url) {
    return url != null && url.trim().isNotEmpty && url != "null";
  }

  Widget buildImage(String? url) {
    if (!isValidImage(url)) {
      return const Icon(Icons.error);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      child: _isAssetImage(url!)
          ? Image.asset(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print("❌ Failed to load asset: $url");
                return const Icon(Icons.error);
              },
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print("❌ Failed to load network image: $url");
                return const Icon(Icons.error);
              },
            ),
    );
  }

  bool _isAssetImage(String url) {
    return url.startsWith('assets/') ||
        url.startsWith('asset:') ||
        !url.startsWith('http') && !url.startsWith('https');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store references safely
    _cardQueue = Provider.of<CardQueueModel>(context, listen: false);
    _filtersProvider = Provider.of<FiltersProvider>(context, listen: false);

    // ADD THIS: Initialize data after providers are available
    if (_cardQueue.isEmpty) {
      getProductData(_cardQueue);
    }

    // ADD THIS: Update widgets if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cardQueue.isNotEmpty) {
        updateCardWidgets(_cardQueue);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    undoController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    undoPositionAnimation =
        Tween<double>(begin: 0, end: 0).animate(undoController);

    transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: transitionController, curve: Curves.easeOut),
    );
    blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: transitionController, curve: Curves.easeOut),
    );

    widget.controller.undo = undo;
    widget.controller.filter = filter;

    greenOpacity = sittingOpacity;
    redOpacity = sittingOpacity;

    // MOVE THIS TO didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // This will be handled in didChangeDependencies
      }
    });
  }

  @override
  void dispose() {
    undoController.dispose();
    transitionController.dispose();
    super.dispose();
  }

  void updateCardWidgets(CardQueueModel cardQueue,
      {bool forceRebuild = false, bool isUndoOperation = false}) {
    // Only rebuild if forced/if card data has changed

    if (isUndoOperation) {
      // For undo operations, we know the first card is the undone card
      // so we should rebuild the current card widget
      _currentCardData = cardQueue.firstCard;
      _currentCardWidget = _currentCardData != null
          ? _buildCard(data: _currentCardData!)
          : const Center(child: CircularProgressIndicator());
    } else if (_nextCardData?.id == cardQueue.firstCard?.id) {
      // Promote next card to current
      _currentCardWidget = _nextCardWidget;
      _currentCardData = _nextCardData;
    } else if (forceRebuild ||
        _currentCardWidget == null ||
        _currentCardData?.id != cardQueue.firstCard?.id) {
      _currentCardData = cardQueue.firstCard;
      _currentCardWidget = _currentCardData != null
          ? _buildCard(data: _currentCardData!)
          : const Center(child: CircularProgressIndicator());
    }
    // Update Next Card
    if (forceRebuild ||
        _nextCardWidget == null ||
        _nextCardData?.id != cardQueue.secondCard?.id) {
      _nextCardData = cardQueue.secondCard;
      _nextCardWidget =
          _nextCardData != null ? _buildCard(data: _nextCardData!) : null;
    }

    // Update the widgets
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = 40;
    final double appBarHeight = 100;
    final double buttonBarHeight = 100;
    double IOSCORRECTION = 0;
    if (kIsWeb) {
      IOSCORRECTION = 0;
    } else if (Platform.isIOS) {
      IOSCORRECTION = 56;
    }
    final double SECONDSEARCHHEIGHT = (50 + 16);
    final padding = MediaQuery.of(context).padding;
    usableScreenHeight = (screenHeight -
        navBarHeight -
        appBarHeight -
        padding.top -
        padding.bottom -
        buttonBarHeight -
        SECONDSEARCHHEIGHT -
        IOSCORRECTION);
    cardWidth = screenWidth * .90;
    cardHeight = usableScreenHeight * .90;
    threshold = MediaQuery.of(context).size.width * .35; // 35% of screen width
    final double screenCenter = MediaQuery.of(context).size.width / 2;
    double currentCardCenterX = _left + cardWidth / 2;

    return Consumer<CardQueueModel>(
      builder: (context, cardQueue, child) {
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withAlpha(64),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(60, 60)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_outlined),
                        iconSize: 32,
                        color: AppColors.error,
                        onPressed: (isButtonAnimating ||
                                cardQueue.isEmpty ||
                                cardQueue.firstCard == null)
                            ? null
                            : () {
                                _triggerNextCardButton(
                                    cardQueue.firstCard!.id, cardQueue, -1);
                              },
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withAlpha(64),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(60, 60)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.bolt),
                        iconSize: 32,
                        color: AppColors.primary,
                        onPressed:
                            (cardQueue.isEmpty || cardQueue.firstCard == null)
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductInfoPage(
                                          product: cardQueue.firstCard!,
                                        ),
                                      ),
                                    );
                                  },
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withAlpha(64),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(60, 60)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.folder_outlined),
                        iconSize: 28,
                        color: AppColors.secondary,
                        onPressed: (isButtonAnimating ||
                                cardQueue.isEmpty ||
                                cardQueue.firstCard == null)
                            ? null
                            : () {
                                _showAddToWardrobeDialog(cardQueue.firstCard!);
                              },
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withAlpha(64),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(60, 60)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.thumb_up),
                        iconSize: 28,
                        color: AppColors.tertiary,
                        onPressed: (isButtonAnimating ||
                                cardQueue.isEmpty ||
                                cardQueue.firstCard == null)
                            ? null
                            : () {
                              print("swiped: ${cardQueue.firstCard?.title}");
                                _triggerNextCardButton(
                                  
                                    cardQueue.firstCard!.id, cardQueue, 1);
                              },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                centerLeft = (screenWidth - cardWidth) / 2;
                centerTop = (usableScreenHeight - cardHeight) / 2;
                if (!_isLoaded) {
                  _left = centerLeft;
                  _top = centerTop;
                  _isLoaded = true;
                  currentCardCenterX = _left + cardWidth / 2;
                }
                if (cardQueue.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (isUndoing) {
                    return Stack(
                      children: [
                        Positioned(
                          left: _left,
                          top: _top,
                          child: AnimatedBuilder(
                            animation: transitionController,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment.center,
                                child: Transform.scale(
                                  scale: scaleAnimation.value,
                                  alignment: Alignment.center,
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: blurAnimation.value,
                                      sigmaY: blurAnimation.value,
                                    ),
                                    child: SizedBox(
                                      width: cardWidth,
                                      height: cardHeight,
                                      child: _nextCardWidget ??
                                          _buildCard(
                                              data: cardQueue.secondCard),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: _left,
                          top: _top,
                          child: AnimatedBuilder(
                            animation: undoController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(undoPositionAnimation.value, 0),
                                child: SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: _currentCardWidget,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Stack(
                      children: <Widget>[
                        // BACKGROUND: The "next" card that sits behind the current card.
                        // When _popUp is true, it is placed exactly in the center.
                        // Otherwise, it shows a blurred preview at a slight offset.
                        //BEHIND ONE
                        AnimatedPositioned(
                          duration: Duration.zero,
                          curve: Curves.easeOut,
                          top:
                              centerTop, // or simply centerTop if you remove the offset
                          left:
                              centerLeft, // or simply centerLeft if you remove the offset
                          child: _buildNextCard(
                              cardQueue), //?: Am i building this every time the thing moves?
                        ),
                        // FOREGROUND: The interactive (current) card.
                        // hide it during pop‑up mode.
                        //IN FRONT ONE
                        if (!_popUp)
                          AnimatedPositioned(
                            //MOVING STUFF
                            duration: _isLoaded
                                ? const Duration(milliseconds: 300)
                                : Duration.zero,
                            top: (_isLoaded) ? _top : centerTop,
                            left: (_isLoaded)
                                ? _left
                                : centerLeft, // Only animate after loading
                            curve: Curves.easeOut,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _top += details.delta.dy;
                                  _left += details.delta.dx;
                                  double distanceFromCenter =
                                      currentCardCenterX - screenCenter;
                                  rotationAngle = distanceFromCenter * 0.0008;
                                  if (distanceFromCenter < 0) {
                                    redOpacity = max(
                                        (distanceFromCenter.abs() / threshold)
                                            .clamp(0.0, 1.0),
                                        sittingOpacity);
                                    greenOpacity = sittingOpacity;
                                  }
                                  if (distanceFromCenter > 0) {
                                    greenOpacity = max(
                                        (distanceFromCenter.abs() / threshold)
                                            .clamp(0.0, 1.0),
                                        sittingOpacity);
                                    redOpacity = sittingOpacity;
                                  }
                                });
                              },
                              onPanEnd: (details) {
                                setState(() {});
                                // If the card was dragged past the threshold, trigger off‑screen animation.
                                if ((currentCardCenterX - screenCenter).abs() >
                                    threshold) {
                                  _triggerNextCard(
                                      cardQueue.firstCard!.id, cardQueue);
                                } else {
                                  _resetCard();
                                }
                              },
                              child: AnimatedRotation(
                                  //Rotating stuff!
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  turns: rotationAngle / (2 * 3.14),
                                  child: _currentCardWidget ??
                                      const SizedBox.shrink()),
                            ),
                          ),
                        Positioned(
                          left: -50, // Adjust based on your layout
                          top: centerTop, // Align vertically with the card
                          child: Container(
                            width: 50,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(
                                      alpha:
                                          redOpacity), // Glow color with transparency
                                  blurRadius: redOpacity *
                                      200, // Increases the glow intensity
                                  spreadRadius: redOpacity *
                                      20, // How much the glow expands
                                  offset:
                                      Offset(0, 0), // Keeps the glow centered
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          // Green Box
                          left: MediaQuery.of(context)
                              .size
                              .width, // Adjust based on your layout
                          top: centerTop, // Align vertically with the card
                          child: Container(
                            width: 50,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.tertiary.withValues(
                                      alpha:
                                          greenOpacity), // Glow color with transparency
                                  blurRadius: greenOpacity *
                                      200, // Increases the glow intensity
                                  spreadRadius: greenOpacity *
                                      20, // How much the glow expands
                                  offset:
                                      Offset(0, 0), // Keeps the glow centered
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }
              }),
            ),
          ],
        );
      },
    );
  }

  /// Builds the next card widget.
  /// When _popUp is true, the next card animates (via scale and blur)
  /// from its preview state to its full appearance.
  Widget _buildNextCard(CardQueueModel cardQueue) {
    if (_popUp) {
      return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (
            context,
            value,
            child,
          ) {
            final double scale = .95 + 0.05 * value;
            final double blur = 5.0 * (1 - value);
            return Align(
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: _currentCardWidget ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          child: _currentCardWidget);
    } else {
      // Preview state: blurred and slightly scaled down.
      return Transform.scale(
        scale: .95,
        child: ClipRRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: _nextCardWidget ?? const SizedBox.shrink(),
          ),
        ),
      );
    }
  }

  /// Builds a card widget from the provided data.
  Widget _buildCard({
    required CardData? data,
  }) {
    if (data == null) {
      return SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    print("buildcard");
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      // Card content
      child: Container(
        //If not
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(64), // about 25 % opacity
                blurRadius: 20,
                blurStyle: BlurStyle.outer,
              )
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildImageSection(data),
              // Product Info
              Expanded(
                // or Flexible
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              data.model ?? data.title,
                              style: TextStyle(
                                  fontSize: cardHeight * .07,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.onSurface),
                              maxLines:
                                  1, // limit so it doesn't take over the screen
                            ),
                            Text(
                              getDisplayPrice(data),
                              style: TextStyle(
                                  fontSize: cardHeight * .05,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(CardData data) {
    // Check if we have valid 360 images
    final hasValid360Images = data.images360.isNotEmpty && 
        data.images360.any((img) => img != null && img != "null" && img.isNotEmpty);
    
    if (hasValid360Images) {
      return SizedBox(
        height: cardHeight * .75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: buildImage(data.images360[3]),
            ),
            Expanded(
              child: buildImage(data.images360[23]),
            ),
          ],
        ),
      );
    }
    
    // Fallback to regular images
    if (data.images.isNotEmpty) {
      final firstImage = data.images.first;
      if (isValidImage(firstImage)) {
        return SizedBox(
          height: cardHeight * .75,
          child: Row(
            children: [
              Expanded(
                child: buildImage(firstImage),
              ),
            ],
          ),
        );
      }
    }
    
    // Fallback to error icon
    return SizedBox(
      height: cardHeight * .75,
      child: const Center(
        child: Icon(Icons.error, size: 50),
      ),
    );
  }

  void _triggerNextCardButton(
      String currentCardID, CardQueueModel cardQueue, int preference) {
    if (isButtonAnimating) return;

    // Use the card currently displayed in the UI
    final CardData? swipedCard = _currentCardData;

    setState(() {
      isButtonAnimating = true;
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final targetLeft = preference > 0
        ? screenWidth + 200 //Right for like
        : -screenWidth - 200; //Left for dislike

    //Animate
    setState(() {
      _left = targetLeft;
      rotationAngle = preference.toDouble() * .5; //change if it looks off
    });

    //After animation trigger next card
    Future.delayed(const Duration(milliseconds: 300), () {
      _triggerNextCard(currentCardID, cardQueue, swipedCard: swipedCard, preference: preference);
    });
  }

  void _triggerNextCard(String currentCardID, CardQueueModel cardQueue, {CardData? swipedCard, int? preference}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final CardData? cardToProcess = swipedCard ?? _currentCardData;
    final currentCardCenterX = _left + cardWidth / 2;
    final screenCenter = screenWidth / 2;
    // Determine which side to fly off (right if swiped right, left otherwise)
    final targetLeft = (currentCardCenterX > screenCenter)
        ? screenWidth + 175
        : -screenWidth - 175;
    final int pref = preference ?? ((currentCardCenterX > screenCenter) ? 1 : -1);
    setState(() {
      _left = targetLeft;
    });
    sendInteraction(currentCardID, pref);
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _popUp = true;
        redOpacity = sittingOpacity;
        greenOpacity = sittingOpacity;
        if (cardQueue.isNotEmpty && cardToProcess != null) {
          final previousShoeModel =
              Provider.of<PreviousProductModel>(context, listen: false);
          previousShoeModel.addSwipe(cardToProcess, pref);
          // Add to liked products if the user liked the card
          if (pref == 1) {
            final likedProductsProvider = Provider.of<LikedProductsProvider>(context, listen: false);
            likedProductsProvider.addLikedProductFromCardData(cardToProcess);
          }
          cardQueue.removeFirstCard();
        }
        updateCardWidgets(cardQueue);
        if (cardQueue.queueLength < CARDSTACKSIZE) {
          getProductData(cardQueue);
        }
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _left = centerLeft;
          _top = centerTop;
          rotationAngle = 0.0;
          _popUp = false;
          isButtonAnimating = false;
        });
      });
    });
  }

  /// Resets the interactive card's position and rotation if the swipe wasn't far enough.
  void _resetCard() {
    setState(() {
      _left = centerLeft;
      _top = centerTop;
      rotationAngle = 0.0;
      redOpacity = sittingOpacity;
      greenOpacity = sittingOpacity;
    });
  }

  void filter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Filters(onFilterChanged: newCards);
      },
    );
  }

  void newCards() {
    final cardQueue = Provider.of<CardQueueModel>(context, listen: false);
    cardQueue.resetQueue();
    getProductData(cardQueue);
  }

  void undo() {
    final previousShoeModel =
        Provider.of<PreviousProductModel>(context, listen: false);

    final previousSwipe = previousShoeModel.getLastSwipe();

    if (previousSwipe != null) {
      final previousCard = previousSwipe['data'] as CardData;
      final cardQueue = Provider.of<CardQueueModel>(context, listen: false);
      //Animation Stuff
      final direction = previousSwipe['direction'] as int;
      final screenWidth = MediaQuery.of(context).size.width;

      cardQueue.addCardFirst(previousCard);

      // Update the card widgets immediately so the animation shows the correct card
      updateCardWidgets(cardQueue, isUndoOperation: true);

      setState(() {
        isUndoing = true;
      });

      undoLeft = direction == 1 ? screenWidth : -screenWidth;
      undoController.reset();
      undoPositionAnimation = Tween<double>(
        begin: undoLeft,
        end: 0,
      ).animate(
          CurvedAnimation(parent: undoController, curve: Curves.easeInOut));

      // Add the undone card back to the queue

      undoController.duration = const Duration(milliseconds: 300);
      undoController.reset();
      undoController.forward();

      undoController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isUndoing = false;
          });
        }
      });

      // Log the queue state
      previousShoeModel.removeLastSwipe();
    } else {
      return;
    }
  }

  Future<void> getProductData(CardQueueModel cardQueue) async {
    try {
      final data = await getProduct();

      // Parse JSON if needed
      final parsedData = data is String ? jsonDecode(data as String) : data;

      if (parsedData is List && parsedData.isNotEmpty) {
        List<CardData> newCards = parsedData.map<CardData>((product) {
          return CardData.fromJson(product);
        }).toList();

        if (!mounted) return;
        setState(() {
          newCards.forEach(cardQueue.addCard);
        });

        updateCardWidgets(cardQueue);
      } else {
        print('No products found in response');
      }
    } catch (e) {
      print('Error fetching shoe data: $e');
    }
  }

  // Calls API
  Future<List<dynamic>> getProduct() async {
    // Use stored reference instead of Provider.of
    final String filters = _filtersProvider.getFiltersString();
    print("filters");
    print(filters);

    final String baseURL =
        ('https://axentbackend.onrender.com/products/recommend/');
    final url = Uri.parse(baseURL).replace(queryParameters: {
      'filters': filters,
    });
    final Dio dio = Dio();

    try {
      final response = await dio.getUri(url,
          options: Options(headers: await getAuthHeaders()));

      if (response.statusCode == 200) {
        // Parse the response data
        final data = response.data;

        // If the data is a string, parse it as JSON
        final parsedData = data is String ? jsonDecode(data) : data;

        return parsedData;
      } else {
        throw Exception(
            'Failed to load recommended shoe: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Status code: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
      print('Error message: ${e.message}');
      throw Exception('Failed to load recommended shoe');
    }
  }

  //Posts to API
  Future<void> sendInteraction(String productID, int liked) async {
    final String baseURL =
        'https://axentbackend.onrender.com/preferences/handle_swipe/';
    final Dio dio = Dio();

    // Get Firebase ID token
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      print("Error: Could not get Firebase ID token.");
      return;
    }

    try {
      final response = await dio.post(
        baseURL,
        data: {
          'product_id': productID,
          'preference': liked.toString(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ),
      );
      if (response.statusCode != 200) {
        print('Server returned status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error response: ${e.response?.data}');
      } else {
        print('Error sending interaction: $e');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  // Smart pricing helper functions (similar to product_info_page.dart)
  double? getRelevantLowestAsk(CardData data) {
    final filtersProvider =
        Provider.of<FiltersProvider>(context, listen: false);
    final userPreferredSizes = filtersProvider.selectedSizes;

    // If user has preferred sizes and product has size-specific pricing
    if (userPreferredSizes.isNotEmpty && data.sizeLowestAsks.isNotEmpty) {
      // Find the lowest ask among user's preferred sizes (ignore 0 values)
      double? lowestAskForUserSizes;

      for (double userSize in userPreferredSizes) {
        // Convert user size to string format (e.g., 10.0 -> "10.0")
        String sizeKey = userSize.toString();

        // Check if this size exists in the product's size pricing
        if (data.sizeLowestAsks.containsKey(sizeKey)) {
          double sizePrice = data.sizeLowestAsks[sizeKey]!;
          // Only consider prices > 0 (ignore unavailable sizes)
          if (sizePrice > 0 &&
              (lowestAskForUserSizes == null ||
                  sizePrice < lowestAskForUserSizes)) {
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
    return data.lowestAsk;
  }

  String getDisplayPrice(CardData data) {
    final relevantLowestAsk = getRelevantLowestAsk(data);

    if (relevantLowestAsk != null) {
      return '\$${relevantLowestAsk.toStringAsFixed(2)}';
    } else {
      return '\$${data.retailPrice.toStringAsFixed(2)}';
    }
  }

  void _showAddToWardrobeDialog(CardData cardData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: AddToWardrobeWidget(product: cardData),
        );
      },
    );
  }
}

Future<Map<String, String>> getAuthHeaders() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user');
      throw Exception("User not authenticated");
    }
    final token = await user.getIdToken(true);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  } catch (e) {
    print('Error in getAuthHeaders: $e');
    rethrow;
  }
}

class FilterColor {
  final Color? color;
  final String label;
  final Gradient? gradient;
  final bool isSpecial;

  FilterColor({
    this.color,
    required this.label,
    this.gradient,
    this.isSpecial = false,
  });
}

class Filters extends StatefulWidget {
  final VoidCallback onFilterChanged;

  const Filters({super.key, required this.onFilterChanged});

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  RangeValues? _currentRangeValues;
  Set<double> _selectedSizes = {};
  Set<FilterColor> selectedColors = {};
  Set<FilterColor> _previousColors = {};
  String? gender;
  String? _previousGender;
  RangeValues? _previousRangeValues;
  Set<double> _previousSizes = {};

  final Completer<void> preferencesReady = Completer<void>();

  final List<FilterColor> colorOptions = [
    FilterColor(color: Colors.red, label: 'Red'),
    FilterColor(color: Colors.orange, label: 'Orange'),
    FilterColor(color: Colors.yellow, label: 'Yellow'),
    FilterColor(color: Colors.green, label: 'Green'),
    FilterColor(color: Colors.blue, label: 'Blue'),
    FilterColor(color: Colors.purple, label: 'Purple'),
    FilterColor(color: Colors.black, label: 'Black'),
    FilterColor(color: Colors.white, label: 'White'),
    FilterColor(color: Colors.brown, label: 'Brown'),
    FilterColor(color: Colors.grey, label: 'Grey'),
    FilterColor(color: Colors.pink, label: 'Pink'),
    FilterColor(color: Colors.teal, label: 'Teal'),
    // 🥇 Metallic
    FilterColor(
      label: 'Metallic',
      isSpecial: true,
      gradient: LinearGradient(
        colors: [
          Colors.grey.shade800,
          Colors.grey.shade400,
          Colors.grey.shade100
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    // 🌈 Multicolor
    FilterColor(
      label: 'Multicolor',
      isSpecial: true,
      gradient: LinearGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
        ],
      ),
    ),
    // 💡 Neon Glow
    FilterColor(
      label: 'Neon',
      isSpecial: true,
      color: Colors.cyanAccent, // base color
    ),
  ];
  void filterChange() {
    final hasGenderChanged = _previousGender != gender;
    final hasPriceChanged = _previousRangeValues != _currentRangeValues;
    final hasSizesChanged =
        !SetEquality().equals(_previousSizes, _selectedSizes);
    final hasColorsChanged =
        !SetEquality().equals(_previousColors, selectedColors);
    if (hasGenderChanged ||
        hasPriceChanged ||
        hasSizesChanged ||
        hasColorsChanged) {
      // Update the previous values
      _previousGender = gender;
      _previousRangeValues = _currentRangeValues;
      _previousSizes = Set.from(_selectedSizes);
      _previousColors = Set.from(selectedColors);

      // Refresh cards
      widget.onFilterChanged();
    }
  }

  Future<void> onGenderButtonPress(
      String newGender, FiltersProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gender', newGender);
    setState(() {
      gender = newGender;
    });
    provider.updateFilters(gender: newGender);
  }

  Future<void> _toggleSize(double size, FiltersProvider provider) async {
    final newSizes = Set<double>.from(_selectedSizes);
    if (newSizes.contains(size)) {
      newSizes.remove(size);
    } else {
      newSizes.add(size);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selectedSizes',
      newSizes.map((e) => e.toString()).toList(),
    );

    setState(() {
      _selectedSizes = newSizes;
    });
    provider.updateFilters(selectedSizes: newSizes);
  }

  Future<void> onPriceRangeChange(
      RangeValues newValues, FiltersProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('minPrice', newValues.start);
    prefs.setDouble('maxPrice', newValues.end);
    setState(() {
      _currentRangeValues = newValues;
    });
    provider.updateFilters(priceRange: newValues);
  }

  Future<void> toggleColor(
      FilterColor newColor, FiltersProvider provider) async {
    final newColors = Set<FilterColor>.from(selectedColors);
    if (newColors.contains(newColor)) {
      newColors.remove(newColor);
    } else {
      newColors.add(newColor);
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'selectedColors',
      newColors.map((color) => color.label).toList(),
    );
    setState(() {
      selectedColors = newColors;
    });
    provider.updateFilters(selectedColors: newColors);
  }

  List<Widget> generateSizeOptions(FiltersProvider provider) {
    final sizes = <double>[];

    // Define size ranges based on gender
    final isKids = gender?.toLowerCase() == 'kids';
    final startSize = isKids ? 1.0 : 6.0;
    final endSize = 16.0;
    final step = 0.5;

    for (double i = startSize; i <= endSize; i += step) {
      sizes.add(i);
    }

    return sizes.map((size) {
      final isSelected = _selectedSizes.contains(size);
      return FilterChip(
        key: ValueKey(size),
        label: Text(
          size == size.toInt() ? size.toInt().toString() : size.toString(),
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _toggleSize(size, provider),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppColors.outline,
          ),
        ),
        showCheckmark: false,
      );
    }).toList();
  }

  closeFilters(context) {
    Navigator.pop(context);
    filterChange();
  }

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGender = prefs.getString('gender') ?? 'Men';
    final minPrice = prefs.getDouble('minPrice') ?? 20.0;
    final maxPrice = prefs.getDouble('maxPrice') ?? 80.0;
    final savedSizes = prefs.getStringList('selectedSizes') ?? [];
    final savedColorLabels = prefs.getStringList('selectedColors') ?? [];

    // Map the saved color labels back to FilterColor objects
    final savedColors = colorOptions
        .where((color) => savedColorLabels.contains(color.label))
        .toSet();

    setState(() {
      gender = savedGender;
      _currentRangeValues = RangeValues(minPrice, maxPrice);
      _selectedSizes = savedSizes.map((e) => double.parse(e)).toSet();
      selectedColors = savedColors;

      // Initialize previous values
      _previousGender = gender;
      _previousRangeValues = _currentRangeValues;
      _previousSizes = Set.from(_selectedSizes);
      _previousColors = Set.from(selectedColors);
    });

    if (!preferencesReady.isCompleted) {
      preferencesReady.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRangeValues == null || gender == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtersProvider = Provider.of<FiltersProvider>(context);
    RangeValues currentRangeValues = _currentRangeValues!;
    return Provider<FiltersProvider>(
      create: (_) => filtersProvider,
      child: _WaitForInitialization(
        initialized: preferencesReady.future,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * .9,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filters",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          )),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.onSurface,
                        onPressed: () {
                          closeFilters(context);
                        },
                      )
                    ],
                  ),
                ),
                // body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Wrap(
                          spacing: 12,
                          children: ['Men', 'Women', 'Unisex', 'Kids']
                              .map((genderMap) {
                            final isSelected = gender == genderMap;
                            return ChoiceChip(
                              label: Text(
                                genderMap,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  onGenderButtonPress(
                                      genderMap, filtersProvider);
                                });
                              },
                              selectedColor: AppColors
                                  .primaryContainer, // light filled background
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: isSelected
                                    ? BorderSide(
                                        color: AppColors.primaryContainer,
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside)
                                    : BorderSide(
                                        color: AppColors.secondaryContainer,
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside),
                              ),
                              elevation: 0,
                              pressElevation: 0,
                              showCheckmark: false,
                              labelPadding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Size',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: generateSizeOptions(filtersProvider),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 16),
                        Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\$${_currentRangeValues!.start.round()}',
                                  style: TextStyle(fontSize: 20)),
                              Text('\$${_currentRangeValues!.end.round()}',
                                  style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          RangeSlider(
                            values: currentRangeValues,
                            min: 0,
                            max: 200,
                            activeColor: AppColors.primary,
                            onChanged: (RangeValues values) {
                              setModalState(() {
                                currentRangeValues = values;
                              });
                              setState(() {
                                _currentRangeValues = values;
                                onPriceRangeChange(values, filtersProvider);
                              });
                            },
                          ),
                        ]),
                        SizedBox(height: 16),
                        Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: colorOptions.length,
                          itemBuilder: (context, index) {
                            final filterColor = colorOptions[index];
                            final isSelected =
                                selectedColors.contains(filterColor);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  toggleColor(filterColor, filtersProvider);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: filterColor.gradient,
                                  color: filterColor.gradient == null
                                      ? filterColor.color
                                      : null,
                                  boxShadow: filterColor.label == 'Neon'
                                      ? [
                                          BoxShadow(
                                            color: (filterColor.color ??
                                                    Colors.cyanAccent)
                                                .withAlpha(128),
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                          )
                                        ]
                                      : [],
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.secondaryContainer,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        color: AppColors.surface, size: 18)
                                    : null,
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Waits for the [initialized] future to complete before rendering [builder].
class _WaitForInitialization extends StatelessWidget {
  const _WaitForInitialization({
    required this.initialized,
    required this.builder,
  });

  final Future<void> initialized;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialized,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const CircularProgressIndicator();
        }
        return builder(context);
      },
    );
  }
}
