import 'package:fashionfrontend/views/widgets/swipeable_card.dart';
import 'package:flutter/material.dart';

class FiltersProvider extends ChangeNotifier {
  String? gender;
  RangeValues? priceRange;
  Set<double> selectedSizes = {};
  Set<FilterColor> selectedColors = {};

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
      if (gender == "men") {
        buffer.write("isMen == true");
      } else if (gender == "women") {
        buffer.write("isWomen == true");
      } else if (gender == "youth") {
        buffer.write("isYouth == true OR isKids == true");
      }
    }

    if (priceRange != null) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write(
          "'retailprice' >= ${priceRange!.start} AND 'retailprice' <= ${priceRange!.end}");
    }

    if (selectedSizes.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write("[\"${selectedSizes.join('" OR "')}\"] in sizes_available");
    }

    if (selectedColors.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write(
          "[\"${selectedColors.map((c) => c.label).join('" OR "')}\"] in 'normalized_colorway'");
    }

    return buffer.toString();
  }
}
