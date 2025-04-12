import 'dart:collection';
import 'package:flutter/material.dart';

class CardData {
  final String title;
  final String price;
  final String description;
  final String info;
  final int id;
  final List<String> images;

  CardData({
    required this.title,
    required this.price,
    required this.description,
    required this.info,
    required this.id,
    required this.images,
  });
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
