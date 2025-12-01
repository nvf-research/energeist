import 'models.dart';

/// Extensions for statistical calculations.
extension ListMath on List<double> {
  /// Calculates the arithmetic mean (average) of the list.
  /// Returns 0.0 if the list is empty.
  double get mean {
    return isEmpty ? 0.0 : reduce((a, b) => a + b) / length;
  }

  /// Calculates the median value of the list.
  /// Returns 0.0 if the list is empty.
  double get median {
    if (isEmpty) return 0.0;

    final sorted = [...this]..sort();
    final mid = sorted.length ~/ 2;

    if (sorted.length.isOdd) return sorted[mid];

    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

/// Extensions for filtering appliance lists.
extension Deduplication on Iterable<EnergyStarNormalizedData> {
  /// Deduplicates appliances based on Brand, Model, and Energy usage.
  List<EnergyStarNormalizedData> distinctAppliances() {
    final seen = <String>{};
    final unique = <EnergyStarNormalizedData>[];

    for (final item in this) {
      // Create a unique composite key
      final key = '${item.brandName?.trim().toUpperCase()}_'
          '${item.modelNumber?.trim().toUpperCase()}_'
          '${item.annualEnergyUseKwhPerYear}';

      if (seen.add(key)) unique.add(item);
    }

    return unique;
  }
}
