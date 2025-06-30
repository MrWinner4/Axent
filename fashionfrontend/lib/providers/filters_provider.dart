import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashionfrontend/app_colors.dart';

class FiltersProvider extends ChangeNotifier {
  String? gender;
  RangeValues? priceRange;
  Set<double> selectedSizes = {};
  Set<FilterColor> selectedColors = {};

  static final List<FilterColor> colorOptions = [
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

  Future<void> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();

    gender = prefs.getString('gender') ?? 'Men';

    final minPrice = prefs.getDouble('minPrice') ?? 20.0;
    final maxPrice = prefs.getDouble('maxPrice') ?? 80.0;
    priceRange = RangeValues(minPrice, maxPrice);

    final savedSizes = prefs.getStringList('selectedSizes') ?? [];
    selectedSizes =
        savedSizes.map((s) => double.tryParse(s)).whereType<double>().toSet();

    final savedColors = prefs.getStringList('selectedColors') ?? [];

    selectedColors = colorOptions
        .where((c) => savedColors.contains(c.label.toLowerCase()))
        .toSet();

    notifyListeners();
  }

  void updateFilters({
    String? gender,
    RangeValues? priceRange,
    Set<double>? selectedSizes,
    Set<FilterColor>? selectedColors,
  }) {
    this.gender = gender ?? this.gender;
    this.priceRange = priceRange ?? this.priceRange;
    this.selectedSizes = selectedSizes ?? this.selectedSizes;
    this.selectedColors = selectedColors ?? this.selectedColors;
    notifyListeners();
  }

  String getFiltersString() {
    final buffer = StringBuffer();

    if (gender != null && gender!.isNotEmpty) {
      if (gender!.toLowerCase() == "men") {
        buffer.write("'isMen' == true");
      } else if (gender!.toLowerCase() == "women") {
        buffer.write("'isWomen' == true");
      } else if (gender!.toLowerCase() == "youth") {
        buffer.write("'isYouth' == true OR 'isKids' == true");
      }
    }

    if (priceRange != null) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write(
          "'retailprice' >= ${priceRange!.start.round()} AND 'retailprice' <= ${priceRange!.end.round()}");
    }

    if (selectedSizes.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" AND ");

      final sizeConditions = selectedSizes
          .map((s) => '"${s.toStringAsFixed(1)}" in \'sizes_available\'')
          .join(" OR ");

      buffer.write("($sizeConditions)");
    }

    if (selectedColors.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write(selectedColors
          .map((c) => '"${c.label.toLowerCase()}" in \'normalized_colorway\'')
          .join(" OR "));
    }

    return buffer.toString();
  }
}
