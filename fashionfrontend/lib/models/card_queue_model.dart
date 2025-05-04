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
    return CardData(
      title: json['title'],
      brand: json['brand'],
      colorway: json['colorway'],
      gender: json['gender'],
      silhouette: json['silhouette'],
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date']) : null,
      retailPrice: double.parse(json['retailprice'].toString()),
      estimatedMarketValue: double.parse(json['estimatedMarketValue'].toString()),
      story: json['story'],
      urls: List<String>.from(json['urls']),
      images: json['images'].map((e) => e['image_url']).toList(),
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

  // Add a card to the queue
  void addCard(CardData data) {
    _queue.addLast(data);
    notifyListeners();
  }

  // Remove the card at the front
  void removeFirstCard() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst();
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

  // Get the card at the front of the queue
  CardData? get firstCard {
    if (_queue.isNotEmpty) {
      return _queue.first;
    }
    return null;
  }
  CardData? get secondCard {
    if (_queue.length > 1) {
      return _queue.elementAt(1);
    }
    return null;
  }
  bool get isEmpty {
    return _queue.isEmpty;
  }
  bool get isNotEmpty {
    return _queue.isNotEmpty;
  }
}

class LikedShoesModel with ChangeNotifier {
  final List<CardData> _likedShoes = <CardData>[];

  List<CardData> get likedShoes => _likedShoes;

  void addItem(CardData data) {
    _likedShoes.add(data);
    notifyListeners();
  }

  void removeLastItem() {
    _likedShoes.removeLast();
    notifyListeners();
  }

  void removeShoe(String shoeId) {
    _likedShoes.removeWhere((shoe) => shoe.id == shoeId);
    notifyListeners();
  }

  bool isShoeLiked(String shoeId) {
    return _likedShoes.any((shoe) => shoe.id == shoeId);
  }
}

class PreviousShoeModel with ChangeNotifier {
  final List<CardData> _likedShoes = <CardData>[];

  List<CardData> get likedShoes => _likedShoes;

  void addItem(CardData data) {
    _likedShoes.add(data);
    notifyListeners();
  }

  void removeLastItem() {
    _likedShoes.removeLast();
    notifyListeners();
  }

  void removeShoe(String shoeId) {
    _likedShoes.removeWhere((shoe) => shoe.id == shoeId);
    notifyListeners();
  }
}