import 'package:flutter/material.dart';

class FiltersProvider extends ChangeNotifier {
  String? gender;
  RangeValues? priceRange;
  Set<double> selectedSizes = {};

  void updateFilters({
    String? gender,
    RangeValues? priceRange,
    Set<double>? selectedSizes,
  }) {
    this.gender = gender ?? this.gender;
    this.priceRange = priceRange ?? this.priceRange;
    this.selectedSizes = selectedSizes ?? this.selectedSizes;
    notifyListeners();
  }

  String getFiltersString() {
    final buffer = StringBuffer();

    if (gender != null && gender!.isNotEmpty) {
      buffer.write("'gender' == \"$gender\"");
    }

    if (priceRange != null) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write(
          "'retailprice' >= ${priceRange!.start} AND 'retailprice' <= ${priceRange!.end}");
    }

    if (selectedSizes.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" AND ");
      buffer.write("'sizes' ANY [${selectedSizes.join(', ')}]");
    }

    return buffer.toString();
  }

  
}
