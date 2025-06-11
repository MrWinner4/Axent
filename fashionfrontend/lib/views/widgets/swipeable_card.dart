import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:fashionfrontend/models/card_queue_model.dart';
import 'package:fashionfrontend/views/pages/heart_page.dart';
import 'package:fashionfrontend/views/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//! FIX: I need to have an "updateCardWidgets()" method along with some widgets for current and next card and only call that method to update the cards and instead call buildcard there
class SwipeableCard extends StatefulWidget {
  final SwipeableCardController controller;

  const SwipeableCard({super.key, required this.controller});

  @override
  State<SwipeableCard> createState() => SwipeableCardState();
}

class SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  final int CARDSTACKSIZE = 3; // How many cards to load at once
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

  late AnimationController undoController;
  late Animation<double> undoPositionAnimation;

  late AnimationController transitionController;
  late Animation<double> scaleAnimation;
  late Animation<double> blurAnimation;



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
    final cardQueue = Provider.of<CardQueueModel>(context, listen: false);
    if (cardQueue.isEmpty) {
      for (int i = 0; i < CARDSTACKSIZE; i++) {
        getProductData(cardQueue);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && cardQueue.isNotEmpty) {
        updateCardWidgets(cardQueue);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void updateCardWidgets(CardQueueModel cardQueue) {
    // Get the current cards from the queue
    final currentCard = cardQueue.firstCard;
    final nextCard = cardQueue.secondCard;

    // Update the widgets
    setState(() {
      // Current card should be the first card in the queue
      _currentCardWidget = currentCard != null
          ? _buildCard(data: currentCard)
          : const Center(child: CircularProgressIndicator());

      // Next card should be the second card in the queue
      _nextCardWidget = nextCard != null ? _buildCard(data: nextCard) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double navBarHeight = 40;
    final double appBarHeight = 100;
    double IOSCORRECTION = 0;
    if (kIsWeb) {
      IOSCORRECTION = 0;
    } else if (Platform.isIOS) {
      IOSCORRECTION = 0;
    }
    final double SECONDSEARCHHEIGHT = (50 + 16);
    final padding = MediaQuery.of(context).padding;
    usableScreenHeight = (screenHeight -
        navBarHeight -
        appBarHeight -
        padding.top -
        padding.bottom -
        SECONDSEARCHHEIGHT -
        IOSCORRECTION);
    cardWidth = screenWidth * .90;
    cardHeight = usableScreenHeight * .90;
    threshold = MediaQuery.of(context).size.width * .35; // 35% of screen width
    final double screenCenter = MediaQuery.of(context).size.width / 2;
    double currentCardCenterX = _left + cardWidth / 2;

    return Consumer<CardQueueModel>(
      builder: (context, cardQueue, child) {
        return LayoutBuilder(builder: (context, constraints) {
          centerLeft = (screenWidth - cardWidth) / 2;
          centerTop = (usableScreenHeight - cardHeight) / 2;
          if (!_isLoaded) {
            _left = centerLeft;
            _top = centerTop;
            _isLoaded = true;
            currentCardCenterX = _left + cardWidth / 2;
          }
          if (cardQueue.isEmpty) {
            return Center(child: CircularProgressIndicator());
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
                                child: _buildCard(
                                  data: cardQueue.secondCard,
                                ),
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
                            child: cardQueue.isEmpty
                                ? _buildCard(
                                    data: null,
                                  )
                                : _currentCardWidget),
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
                            color: Color.fromRGBO(237, 8, 8, 1).withValues(
                                alpha:
                                    redOpacity), // Glow color with transparency
                            blurRadius: redOpacity *
                                200, // Increases the glow intensity
                            spreadRadius:
                                redOpacity * 20, // How much the glow expands
                            offset: Offset(0, 0), // Keeps the glow centered
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
                            color: Color.fromRGBO(0, 255, 106, 1).withValues(
                                alpha:
                                    greenOpacity), // Glow color with transparency
                            blurRadius: greenOpacity *
                                200, // Increases the glow intensity
                            spreadRadius:
                                greenOpacity * 20, // How much the glow expands
                            offset: Offset(0, 0), // Keeps the glow centered
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        });
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
                child: child,
              ),
            ),
          );
        },
        child:
            cardQueue.isNotEmpty ? _currentCardWidget : _buildCard(data: null),
      );
    } else {
      // Preview state: blurred and slightly scaled down.
      return Transform.scale(
        scale: .95,
        child: ClipRRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: _nextCardWidget,
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
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      // Card content
      child: Container(
        //If not
        decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceBright,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ColorScheme.of(context)
                    .primary
                    .withAlpha(64), // about 25 % opacity
                blurRadius: 20,
                blurStyle: BlurStyle.outer,
              )
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: ColoredBox(
                  color: Colors.white,
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight * (30 / 40),
                    // Replace the current image section with:
                    child: data.images.length >= 2
                        ? Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  data.images[0],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: Image.network(
                                  data.images[1],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : Image.network(
                            data.images.first,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error),
                              );
                            },
                          ),
                  ),
                ),
              ),
              // Image, Defines bounds and stuff
              // Product Info
              Expanded(
                // or Flexible
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines:
                              2, // limit so it doesn't take over the screen
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${data.estimatedMarketValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
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

  /// Called when the swipe passes the threshold.
  /// This version first animates the current card off-screen,
  /// then triggers the "pop-up" of the next card from its blurred position.
  ///

  void _triggerNextCard(String currentCardID, CardQueueModel cardQueue) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swipedCard = cardQueue.firstCard;
    final currentCardCenterX = _left + cardWidth / 2;
    final screenCenter = screenWidth / 2;
    // Determine which side to fly off (right if swiped right, left otherwise)
    final targetLeft = (currentCardCenterX > screenCenter)
        ? screenWidth + 175
        : -screenWidth - 175;
    final int preference = (currentCardCenterX > screenCenter) ? 1 : -1;
    // Animate the current card off-screen.
    setState(() {
      _left = targetLeft;
    });
    sendInteraction(currentCardID, preference);
    // Wait for the off-screen animation to complete.
    Future.delayed(const Duration(milliseconds: 300), () {
      // Trigger the next card's pop‑up animation.
      setState(() {
        _popUp = true;
        redOpacity = sittingOpacity;
        greenOpacity = sittingOpacity;
        if (cardQueue.isNotEmpty) {
          cardQueue.removeFirstCard();
          //Add previous swipe to previousProductModel
          final previousShoeModel =
              Provider.of<PreviousProductModel>(context, listen: false);
          previousShoeModel.addSwipe(swipedCard!, preference);
        }
        updateCardWidgets(cardQueue);
        getProductData(cardQueue);
      });
      // After the pop‑up animation, update the index and reset positions instantly.
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          // **Update the card index here so that the next card becomes the current card.**
          _left = centerLeft;
          _top = centerTop;
          rotationAngle = 0.0;
          _popUp = false;
        });
      });
    });
  }

  /// Resets the interactive card's position and rotation if the swipe wasn’t far enough.
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
        return Filters();
      },
    );
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

      setState(() {
        _currentCardWidget = _buildCard(data: previousCard);
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
            updateCardWidgets(cardQueue);
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

      // Parse JSON if data is a string
      final parsedData = data is String ? jsonDecode(data as String) : data;

      if (parsedData is List && parsedData.isNotEmpty) {
        List<CardData> newCards = parsedData.map<CardData>((product) {
          return CardData(
            title: product['title'] ?? 'No Name',
            brand: product['brand'] ?? '',
            colorway: product['colorway'] ?? '',
            gender: product['gender'] ?? '',
            silhouette: product['silhouette'] ?? '',
            releaseDate: product['release_date'] != null
                ? DateTime.tryParse(product['release_date'])
                : null,
            retailPrice:
                double.tryParse(product['retailprice'].toString()) ?? 0.0,
            estimatedMarketValue:
                double.tryParse(product['estimatedMarketValue'].toString()) ??
                    0.0,
            story: product['story'] ?? '',
            urls: List<String>.from(product['urls'] ?? []),
            images: (product['images'] is List)
                ? (product['images'] as List)
                    .map((e) => e['image_url'] ?? '')
                    .toList()
                    .cast<String>()
                : ['assets/images/Shoes1.jpg'],
            id: product['id'] ?? '',
            likedAt: DateTime.now(),
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          // Add all new cards to the card queue
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
    final filters =
        "'brand' in [\"Nike\", \"Adidas\"] AND 'retailPrice' <= 200'";

    final String baseURL =
        ('https://axentbackend.onrender.com/products/recommend/');
    final url = Uri.parse(baseURL).replace(queryParameters: {
      'filters': filters,
    });
    final Dio dio = Dio();
    print(await getAuthHeaders());

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
      } else {
        final likedPage = context.findAncestorStateOfType<HeartPageState>();
        if (likedPage != null) {
          likedPage.refreshLikedProducts();
        }
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

class Filters extends StatefulWidget {
  const Filters({super.key});

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  RangeValues _currentRangeValues = const RangeValues(20, 80);

  final Completer<void> preferencesReady = Completer<void>();

  String gender = "Men";

  Future<void> onGenderButtonPress(String newGender) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gender', newGender);
    setState(() {
      gender = newGender;
    });
  }

  Future<void> loadSelectedGender() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gender = prefs.getString('gender') ?? 'Male';
    });
  }

  @override
  void initState() {
    super.initState();
    loadSelectedGender();
    preferencesReady.complete();
  }
  

  @override
  Widget build  (BuildContext context) {
    RangeValues currentRangeValues = _currentRangeValues;
    return _WaitForInitialization(
      initialized: preferencesReady.future,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * .9,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () => Navigator.pop(context),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Wrap(
                        spacing: 12,
                        children: ['Men', 'Women', 'Unisex'].map((genderMap) {
                          final isSelected = gender == genderMap;
                          return ChoiceChip(
                            label: Text(
                              genderMap,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                onGenderButtonPress(genderMap);
                              });
                            },
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer, // light filled background
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isSelected
                                  ? BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      width: 1.5,
                                      strokeAlign: BorderSide.strokeAlignInside)
                                  : BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                      strokeAlign: BorderSide.strokeAlignInside),
                            ),
                            elevation: 0,
                            pressElevation: 0,
                            showCheckmark: false,
                            labelPadding:
                                EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 16),
                      Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${_currentRangeValues.start.round()}',
                                style: TextStyle(fontSize: 20)),
                            Text('\$${_currentRangeValues.end.round()}',
                                style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        RangeSlider(
                          values: currentRangeValues,
                          min: 0,
                          max: 200,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (RangeValues values) {
                            setModalState(() {
                              currentRangeValues = values;
                            });
                            setState(() {
                              _currentRangeValues = values;
                            });
                          },
                        ),
                      ]),
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