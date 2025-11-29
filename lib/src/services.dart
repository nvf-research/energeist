import 'dart:convert';
import 'package:http/http.dart' as http;
import 'enums.dart';
import 'models.dart';

/// Service for interacting with EnergyStar API using dataset IDs directly.
///
/// Provides methods to fetch appliance data from the Energy Star API.
class EnergyStarService {
  static const String baseUrl = 'https://data.energystar.gov/resource';

  /// Creates an [EnergyStarService] instance.
  EnergyStarService();

  /// Searches for appliances across multiple Energy Star datasets.
  /// Queries one or more dataset IDs and aggregates results. Each dataset
  /// represents a specific appliance type.
  ///
  /// Parameters:
  /// - [datasetIds] - Set of Energy Star dataset IDs to query
  /// - [brandName] - Optional brand name filter
  /// - [modelNumber] - Optional model number filter
  /// - [additionalFilters] - Optional additional query parameters
  ///
  /// Returns a list of normalized appliance data from all queried datasets.
  /// If a dataset query fails, it logs an error and continues with remaining datasets.
  Future<List<EnergyStarNormalizedData>> searchByDatasetIds({
    required Set<String> datasetIds,
    String? brandName,
    String? modelNumber,
    Map<String, String>? additionalFilters,
  }) async {
    final List<EnergyStarNormalizedData> allResults = [];

    for (final datasetId in datasetIds) {
      final queryParams = <String, String>{
        ...?additionalFilters,
      };

      // Build case-insensitive $where clause for brand and model
      final whereClauses = <String>[];
      if (brandName != null)
        whereClauses
            .add("upper(brand_name)='${brandName.trim().toUpperCase()}'");

      if (modelNumber != null)
        whereClauses
            .add("upper(model_number)='${modelNumber.trim().toUpperCase()}'");

      if (whereClauses.isNotEmpty)
        queryParams['\$where'] = whereClauses.join(' AND ');

      try {
        final results = await _fetchDataFromDatasetId(datasetId, queryParams);
        allResults.addAll(results);
      } catch (e) {
        print('Error fetching data from dataset $datasetId: $e');
      }
    }

    // Remove duplicates if same brand + model + energy consumption
    final seen = <String>{};
    final deduped = <EnergyStarNormalizedData>[];
    for (final item in allResults) {
      final key =
          '${item.brandName?.toUpperCase()}_${item.modelNumber?.toUpperCase()}_${item.annualEnergyUseKwhPerYear}';
      if (seen.add(key)) deduped.add(item);
    }

    return deduped;
  }

  /// Fetches data from a single Energy Star dataset ID.
  /// Makes an HTTP GET request to the Energy Star API with the specified
  /// dataset ID and query parameters.
  ///
  /// Parameters:
  /// - [datasetId] - Energy Star dataset identifier
  /// - [queryParams] - Query string parameters for filtering results
  ///
  /// Returns a list of normalized appliance data.
  /// Throws an exception if the API request fails.
  Future<List<EnergyStarNormalizedData>> _fetchDataFromDatasetId(
    String datasetId,
    Map<String, String> queryParams,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/$datasetId.json',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => EnergyStarNormalizedData.fromJson(json, datasetId))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch EnergyStar data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching EnergyStar data: $e');
      rethrow;
    }
  }
}

/// Service that estimates appliance energy consumption from minimal inputs.
/// Uses Energy Star API data to calculate median energy usage for appliances
/// based on type, brand, and model information.
class Estimator {
  final EnergyStarService _energyStarService = EnergyStarService();

  /// Creates an [Estimator] instance.
  Estimator();

  /// Estimates appliance energy usage from Energy Star data.
  /// Queries the Energy Star API for appliances matching the provided criteria
  /// and returns the aggregated annual energy consumption based on the chosen strategy.
  ///
  /// Search strategy:
  /// - If only [type] provided: searches all appliances of that type
  /// - If [type] + [brandName]: searches by brand within type
  /// - If all three provided: searches for exact brand+model match
  ///
  /// Parameters:
  /// - [type] - Appliance type
  /// - [brandName] - Optional brand name (case-insensitive)
  /// - [modelNumber] - Optional model number (case-insensitive)
  /// - [strategy] - Aggregation strategy (median or mean). Defaults to median.
  ///
  /// Returns the aggregated annual energy usage in kWh/year based on the chosen strategy.
  /// Returns 0.0 if no matching appliances are found.
  Future<double> estimate({
    required ApplianceInfo type,
    String? brandName,
    String? modelNumber,
    Strategy strategy = Strategy.median,
  }) async {
    // Normalize inputs
    final normalizedBrand =
        brandName != null ? _normalizeBrandName(brandName) : null;
    final normalizedModel =
        modelNumber != null ? modelNumber.trim().toUpperCase() : null;

    // Fetch data from EnergyStar
    final records = await _energyStarService.searchByDatasetIds(
      datasetIds: type.datasetIds,
      brandName: normalizedBrand,
      modelNumber: normalizedModel,
    );

    if (records.isEmpty) return 0.0;

    final values = _extractEnergyValues(records);

    return switch (strategy) {
      Strategy.median => _calculateMedian(values),
      Strategy.mean => _calculateMean(values),
    };
  }

  /// Extracts annual energy usage values from normalized records.
  ///
  /// Returns a list of energy consumption values in kWh/year.
  static List<double> _extractEnergyValues(
    Iterable<EnergyStarNormalizedData> records,
  ) {
    final values = <double>[];
    for (final record in records) values.add(record.annualEnergyUseKwhPerYear);

    return values;
  }

  /// Calculates the median value from a list of numbers.
  static double _calculateMedian(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;

    if (sorted.length.isOdd) return sorted[mid];

    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Calculates the arithmetic mean (average) of a list of numbers.
  static double _calculateMean(List<double> values) {
    final sum = values.reduce((a, b) => a + b);

    return sum / values.length;
  }

  /// Normalizes brand names for consistent API queries.
  ///
  /// Converts to uppercase and trims whitespace to match Energy Star API format.
  static String _normalizeBrandName(String brandName) {
    return brandName.trim().toUpperCase();
  }
}
