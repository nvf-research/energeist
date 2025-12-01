import 'dart:convert';
import 'package:http/http.dart' as http;
import 'enums.dart';
import 'models.dart';
import 'extensions.dart';

class EnergyStarService {
  static const String _baseUrl = 'https://data.energystar.gov/resource';

  /// Fetches and aggregates appliance data from multiple datasets in parallel.
  ///
  /// Parameters:
  /// - [datasetIds] - Set of Energy Star dataset IDs to fetch from
  /// - [brandName] - Optional brand name filter
  /// - [modelNumber] - Optional model number filter
  ///
  /// Returns a deduplicated list of normalized appliance data.
  Future<List<EnergyStarNormalizedData>> fetchAppliances({
    required Set<String> datasetIds,
    String? brandName,
    String? modelNumber,
  }) async {
    final queryParams = _buildQueryParams(brandName, modelNumber);
    final tasks = datasetIds.map((id) => _fetchFromDataset(id, queryParams));
    final results = await Future.wait(tasks);

    return results.expand((list) => list).distinctAppliances().toList();
  }

  /// Builds query parameters for filtering appliances by brand and model.
  /// Performs case-insensitive matching by converting values to uppercase.
  ///
  /// Parameters:
  /// - [brand] - Optional brand name to filter by
  /// - [model] - Optional model number to filter by
  ///
  /// Returns a map of query parameters for the Energy Star API.
  Map<String, String> _buildQueryParams(String? brand, String? model) {
    final whereClauses = <String>[];

    if (brand != null)
      whereClauses.add("upper(brand_name)='${brand.trim().toUpperCase()}'");

    if (model != null)
      whereClauses.add("upper(model_number)='${model.trim().toUpperCase()}'");

    return whereClauses.isNotEmpty
        ? {'\$where': whereClauses.join(' AND ')}
        : {};
  }

  /// Fetches appliance data from a single Energy Star dataset.
  ///
  /// Parameters:
  /// - [datasetId] - The Energy Star dataset ID to fetch from
  /// - [queryParams] - Query parameters for filtering the results
  ///
  /// Returns a list of normalized appliance data, or an empty list if the request fails.
  Future<List<EnergyStarNormalizedData>> _fetchFromDataset(
    String datasetId,
    Map<String, String> queryParams,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/$datasetId.json')
          .replace(queryParameters: queryParams);

      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((j) => EnergyStarNormalizedData.fromJson(j, datasetId))
            .toList();
      }

      print('Warning: Dataset $datasetId failed with ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching dataset $datasetId: $e');
      return [];
    }
  }
}

class Estimator {
  final EnergyStarService _service;

  Estimator({EnergyStarService? service})
      : _service = service ?? EnergyStarService();

  /// Estimates annual energy usage in kWh/year for a given appliance type.
  ///
  /// Parameters:
  /// - [type] - The type of appliance to estimate energy usage for
  /// - [brandName] - Optional brand name filter (case-insensitive)
  /// - [modelNumber] - Optional model number filter (case-insensitive)
  /// - [strategy] - Statistical strategy to use (median or mean, defaults to median)
  ///
  /// Returns the estimated annual energy usage in kWh/year, or 0.0 if no matches found.
  Future<double> estimate({
    required ApplianceInfo type,
    String? brandName,
    String? modelNumber,
    Strategy strategy = Strategy.median,
  }) async {
    final appliances = await _service.fetchAppliances(
      datasetIds: type.datasetIds,
      brandName: brandName,
      modelNumber: modelNumber,
    );

    if (appliances.isEmpty) return 0.0;

    final energyValues =
        appliances.map((e) => e.annualEnergyUseKwhPerYear).toList();

    return switch (strategy) {
      Strategy.median => energyValues.median,
      Strategy.mean => energyValues.mean,
    };
  }
}
