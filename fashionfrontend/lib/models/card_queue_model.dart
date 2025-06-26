import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class CardData {
  final String id;
  final String title;
  final String brand;
  final String? model;
  final String? description;
  final String? sku;
  final String? slug;
  final String? category;
  final String? secondaryCategory;
  final bool upcoming;
  final DateTime? updatedAt;
  final String? link;
  final List<String> colorway;
  final bool trait;
  final DateTime? releaseDate;
  final double retailPrice;
  final List<String> images;
  final List<String> images360;
  final DateTime likedAt;

  CardData({
    required this.id,
    required this.title,
    required this.brand,
    this.model,
    this.description,
    this.sku,
    this.slug,
    this.category,
    this.secondaryCategory,
    required this.upcoming,
    this.updatedAt,
    this.link,
    required this.colorway,
    required this.trait,
    this.releaseDate,
    required this.retailPrice,
    required this.images,
    required this.likedAt,
    required this.images360
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      try {
        return double.parse(value.toString().replaceAll(',', ''));
      } catch (e) {
        print('Error parsing price: $e');
        return 0.0;
      }
    }

    return CardData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'],
      description: json['description'],
      sku: json['sku'],
      slug: json['slug'],
      category: json['category'],
      secondaryCategory: json['secondary_category'],
      upcoming: json['upcoming'] ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      link: json['link'],
      colorway: json['colorway'] is List
          ? List<String>.from(json['colorway'])
          : [],
      trait: json['trait'] ?? false,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      retailPrice: parsePrice(json['retailprice']),
      images: json['images'] is List
          ? (json['images'] as List)
              .map((e) => e['image_url'].toString())
              .toList()
          : ['assets/images/Shoes1.jpg'],
      likedAt: DateTime.now(),
      images360: json['360images'] is List
          ? (json['images360'] as List)
            .map((e) => e['image360_url'].toString())
            .toList()
          : ['assets/images/Shoes1.jpg']
    );
  }

  String get formattedPrice => '\$${retailPrice.toStringAsFixed(2)}';
}

class CardQueueModel with ChangeNotifier {
  final Queue<CardData> _queue = Queue<CardData>();

  Queue<CardData> get queue => _queue;

  void addCardFirst(CardData data){
    _queue.addFirst(data);
  }

  void addCard(CardData data) {
    // Always keep 3 cards in the queue
    _queue.addLast(data);
    notifyListeners();
  }

  void removeFirstCard() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst();
      notifyListeners();
    }
  }
  void removeLastCard() {
    // ignore: unnecessary_null_comparison
    if (_queue.last != null) {
      _queue.removeLast();
      notifyListeners();
    }
  }

  // Clear or reset the queue
  void resetQueue() {
    _queue.clear();
    notifyListeners();
  }

  int get queueLength {
    return _queue.length;
  }

  CardData? get firstCard {
    return _queue.isNotEmpty ? _queue.first : null;
  }

  CardData? get secondCard {
    return _queue.length > 1 ? _queue.elementAt(1) : null;
  }

  CardData? get thirdCard {
    return _queue.length > 2 ? _queue.elementAt(2) : null;
  }

  bool get isEmpty {
    return _queue.isEmpty;
  }

  bool get isNotEmpty {
    return _queue.isNotEmpty;
  }
}

class PreviousProductModel with ChangeNotifier {
  final List<Map<String, dynamic>> _previousShoes = [];

  List<Map<String, dynamic>> get previousShoes => _previousShoes;

  void addSwipe(CardData data, int direction) {
    _previousShoes.add({
      'data': data,
      'direction': direction, // 1 for right swipe, -1 for left swipe
    });
    notifyListeners();
  }

  Map<String, dynamic>? getLastSwipe() {
    if (_previousShoes.isEmpty) return null;
    return _previousShoes.last;
  }

  void removeLastSwipe() {
    if (_previousShoes.isNotEmpty) {
      _previousShoes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _previousShoes.clear();
    notifyListeners();
  }
}