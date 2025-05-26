import 'dart:collection';
import 'package:flutter/material.dart';

class CardData {
  final String title;
  final String brand;
  final String colorway;
  final String gender;
  final String silhouette;
  final DateTime? releaseDate;
  final double retailPrice;
  final double estimatedMarketValue;
  final String story;
  final List<String> urls;
  final List<String> images;
  final String id;
  final DateTime likedAt;

  CardData({
    required this.title,
    required this.brand,
    required this.colorway,
    required this.gender,
    required this.silhouette,
    this.releaseDate,
    required this.retailPrice,
    required this.estimatedMarketValue,
    required this.story,
    required this.urls,
    required this.images,
    required this.id,
    required this.likedAt,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    double parsePrice(String? priceStr) {
      if (priceStr == null) return 0.0;
      try {
        return double.parse(priceStr.replaceAll(',', ''));
      } catch (e) {
        print('Error parsing price: $e');
        return 0.0;
      }
    }

    return CardData(
      title: json['title'],
      brand: json['brand'],
      colorway: json['colorway'],
      gender: json['gender'],
      silhouette: json['silhouette'],
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date']) : null,
      retailPrice: parsePrice(json['retailprice'].toString()),
      estimatedMarketValue: parsePrice(json['estimatedMarketValue'].toString()),
      story: json['story'],
      urls: List<String>.from(json['urls']),
      images: json['images'].map((e) => e['image_url'].toString()).toList(),
      id: json['id'],
      likedAt: DateTime.now(),
    );
  }

  String get formattedPrice {
    return '\$${retailPrice.toStringAsFixed(2)}';
  }
}

class CardQueueModel with ChangeNotifier {
  final Queue<CardData> _queue = Queue<CardData>();

  Queue<CardData> get queue => _queue;

  void addCardFirst(CardData data){
    _queue.addFirst(data);
  }

  void addCard(CardData data) {
    // Always keep 3 cards in the queue
    if (_queue.length >= 3) {
      _queue.removeLast();
    }
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