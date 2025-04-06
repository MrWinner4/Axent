import 'dart:math';
import 'dart:ui';
import 'package:fashionfrontend/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:collection';

//TODO: working on cardHeight
//TODOS: get favorites/saved/profile page working, Get back button to work
//TODOS: Get the swipeable card to work with the data from the database
//TODOS: Finish connecting front and backend, flesh out liked & settings page, make ios look like ios(material vs. ios) figure out account setup & authentication, monitization
//! FIX: I need to have an "updateCardWidgets()" method along with some widgets for current and next card and only call that method to update the cards and instead call buildcard there
//! FIX: I need to make everything relative to screen size so stuff doesn't start going everywhere

/* 
  import 'package:flutter_svg/flutter_svg.dart';
  Code for Back Button
  CircleAvatar(
    backgroundColor: Color.fromRGBO(56, 75, 85, 1),
    maxRadius: 15,
    child: SvgPicture.asset(
      'assets/icons/backbutton.svg',
        colorFilter: ColorFilter.mode(
          Color.fromARGB(255, 246, 248, 249),
          BlendMode.srcIn,
        ),
      ),
  ),
  Makes the most sense to go in the home_page somwewhere
 */
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({Key? key}) : super(key: key);

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class CardData {
  final String title;
  final String price;
  final String description;
  final String info;
  final List<String> images;

  CardData({
    required this.title,
    required this.price,
    required this.description,
    required this.info,
    required this.images,
  });
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
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
  //Threshold for swipe, need to go this far to trigger a swipe
  late double threshold;
  //Is the card Loaded?
  bool _isLoaded = false;
  //For cycling through fake data
  int currentCardIndex = 0;
  // Ff true, the next card animates (pops up) from behind
  bool _popUp = false;
  // Center coordinates for the card.
  late double centerLeft = 0;
  late double centerTop = 0;

  // Card data list, only fofr temporary use

  Queue<CardData> cardQueue = Queue<CardData>();

  @override
  void initState() {
    super.initState();
    greenOpacity = sittingOpacity;
    redOpacity = sittingOpacity;
    for (int i = 0; i < 3; i++) {
      getShoeData();
    }
    cardQueue.add(
      CardData(
        title: 'Air Jordans',
        price: '\$159.99',
        description: 'Flashy, red, and classic.',
        info: 'We flagged this item as:\nRed\nAir Jordan\nHigh Top',
        images: ['assets/images/watch.png'],
      ),
    );
    cardQueue.add(
      CardData(
        title: 'Air Jordans',
        price: '\$159.99',
        description: 'Flashy, red, and classic.',
        info: 'We flagged this item as:\nRed\nAir Jordan\nHigh Top',
        images: ['assets/images/watch.png'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double navBarHeight = NavbarWidget().preferredSize.height;
    double appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    final padding = MediaQuery.of(context).padding;
    cardWidth = screenWidth;
    cardHeight = screenHeight - navBarHeight - appBarHeight - padding.top - padding.bottom;
    print("screenHeight");
    print(screenHeight);
    print("navbarHeight");
    print(navBarHeight);
    print("appBarHeight");
    print(appBarHeight);
    print("padding");
    print(padding.top);
    print(padding.bottom);


    print(cardHeight);
    threshold = MediaQuery.of(context).size.width * .35; // 35% of screen width
    final double screenCenter = MediaQuery.of(context).size.width / 2;
    double currentCardCenterX = _left + cardWidth / 2;
    return LayoutBuilder(builder: (context, constraints) {
      centerLeft = 0;
      centerTop = 0;
      if (!_isLoaded) {
        _left = centerLeft;
        _top = centerTop;
        _isLoaded = true;
        currentCardCenterX = _left + cardWidth / 2;
      }
      return Stack(
        children: <Widget>[
          // BACKGROUND: The "next" card that sits behind the current card.
          // When _popUp is true, it is placed exactly in the center.
          // Otherwise, it shows a blurred preview at a slight offset.
          //BEHIND ONE
          AnimatedPositioned(
            duration: Duration.zero,
            curve: Curves.easeOut,
            top: centerTop, // or simply centerTop if you remove the offset
            left: centerLeft, // or simply centerLeft if you remove the offset
            child:
                _buildNextCard(), //?: Am i building this every time the thing moves?
          ),
          // FOREGROUND: The interactive (current) card.
          // hide it during pop‑up mode.
          //IN FRONT ONE
          if (!_popUp)
            AnimatedPositioned(
              //MOVING STUFF
              duration:
                  _isLoaded ? const Duration(milliseconds: 300) : Duration.zero,
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
                  if ((currentCardCenterX - screenCenter).abs() > threshold) {
                    _triggerNextCard();
                  } else {
                    _resetCard();
                  }
                },
                child: AnimatedRotation(
                  //ROTATING STUFF
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  turns: rotationAngle / (2 * 3.14),
                  child: cardQueue.isEmpty
                      ? _buildCard(
                          data: null,
                          showBorder: true,
                        ) //THIS NEEDS TO BE THE DATA FROM THE NEXT QUEUE CARD)
                      : _buildCard(
                          //WHAT'S INSIDE THE CARD STUFF
                          data: cardQueue.first, //THIS NEEDS TO BE THE DATA FROM THE NEXT QUEUE CARD?
                          showBorder: false,
                        ),
                ),
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
                        alpha: redOpacity), // Glow color with transparency
                    blurRadius:
                        redOpacity * 200, // Increases the glow intensity
                    spreadRadius: redOpacity * 20, // How much the glow expands
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
                        alpha: greenOpacity), // Glow color with transparency
                    blurRadius:
                        greenOpacity * 200, // Increases the glow intensity
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
    });
  }

  /// Builds the next card widget.
  /// When _popUp is true, the next card animates (via scale and blur)
  /// from its preview state to its full appearance.
  Widget _buildNextCard() {
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
        child: cardQueue.isNotEmpty
            ? _buildCard(data: cardQueue.first, showBorder: true)
            : _buildCard(data: null, showBorder: true),
      );
    } else {
      // Preview state: blurred and slightly scaled down.
      return Transform.scale(
        scale: .95,
        child: ClipRRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: _buildCard(data: cardQueue.elementAt(1), showBorder: false),
          ),
        ),
      );
    }
  }

  /// Builds a card widget from the provided data.
  Widget _buildCard({
    required CardData? data,
    required bool showBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all()
      ),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        // Card content
        child: data == null
            ? const Center(
                //If the data is null
                child: Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ))
            : Container(
                //If not
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 249, 181, 79), //TODO needs to be gradient
                  gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 202, 202, 202), //Ending Color
                        const Color.fromARGB(
                            255, 255, 255, 255), //Beginning Color
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.0, .2]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Icon
                    Align(
                      alignment: Alignment.topLeft,
                      child: ColoredBox(
                        color: Color.fromARGB(255, 255, 255, 255),
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight * (30 / 40),
                          child: Image.asset(
                              'assets/images/Shoes3.jpg'), //! NEEDS TO BE A CALL FOR AN IMAGE FROM THE DATABASE/JUST THE IMAGE PROVIDED FROM THE CALL FOR THE ITME
                        ),
                      ),
                    ),
                    // Image, Defines bounds and stuff
                    // Product Info
                    SizedBox(
                      height: cardHeight * (8 / 40),
                      child: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                data.title,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 29, 37, 43),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 45,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                data.price,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 29, 37, 43),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 32,
                                  height: 1,
                                ),
                              ),
                            ],
                          )),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  /// Called when the swipe passes the threshold.
  /// This version first animates the current card off-screen,
  /// then triggers the "pop-up" of the next card from its blurred position.
  void _triggerNextCard() {
    final screenWidth = MediaQuery.of(context).size.width;
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
    sendInteraction(UserID, ProductID, preference);
    // Wait for the off-screen animation to complete.
    Future.delayed(const Duration(milliseconds: 300), () {
      // Trigger the next card's pop‑up animation.
      setState(() {
        _popUp = true;
        redOpacity = sittingOpacity;
        greenOpacity = sittingOpacity;
        if (cardQueue.isNotEmpty) {
          cardQueue.removeFirst();
        }
        getShoeData();
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

  Future<void> getShoeData() async {
  print("gettingShoe");
  try {
    final data = await getShoe(); // Directly using the response as a Map
    print(data);

    final newCard = CardData(
      title: data['name'] ?? 'No Name',
      description: data['category'] ?? '',
      info: 'features:\n${data['features']?.toString() ?? ''}', // Safely convert features to string
      images: (data['images'] is List) 
          ? (data['images'] as List).map((e) => e.toString()).toList() 
          : ['assets/images/Shoes1.jpg'], // Default if images is not a list
      price: '\$${data['price']?.toString() ?? '0.00'}', // Handle missing price gracefully
    );

    setState(() {
      cardQueue.add(newCard);
    });
    } catch (e) {
    print('Error fetching shoe data: $e');
  }
}


// Calls API
  Future<Map<String, dynamic>> getShoe() async {
    final String baseURL = ('http://192.168.0.141:8000/products/recommend/');
    final url = Uri.parse(baseURL);
    final Dio dio = Dio();
    final response = await dio.getUri(url);

    if (response.statusCode == 200) {
      // Parse the JSON response into a Map
      return (response.data);
    } else {
      throw Exception('Failed to load recommended shoe');
    }
  }
}

//Posts to API
  Future<void> sendInteraction(String UserID, String ProductID, int liked) async {
    final String baseURL = ('http://192.168.0.141:8000/interaction/');
    final Dio dio = Dio();
    final response = await dio.post(
      baseURL,
      data: {
        'user_id': UserID,
        'product_id': ProductID,
        'liked': liked,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
