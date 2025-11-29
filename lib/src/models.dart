import 'enums.dart';

/// Normalized data model for Energy Star API responses.
/// Extracts and standardizes fields from various Energy Star dataset formats
/// into a consistent structure for easy consumption by parent systems.
class EnergyStarNormalizedData {
  final String? brandName;
  final String? modelNumber;
  final double annualEnergyUseKwhPerYear;
  final Map<String, dynamic> additionalFields;
  final String datasetId;
  final String? applianceType;

  /// Creates a normalized data instance.
  EnergyStarNormalizedData({
    this.brandName,
    this.modelNumber,
    required this.annualEnergyUseKwhPerYear,
    required this.additionalFields,
    required this.datasetId,
    this.applianceType,
  });

  /// Creates a normalized data instance from Energy Star API JSON response.
  /// Attempts to extract common fields using multiple field name variations,
  /// as different datasets use different naming conventions.
  ///
  /// Parameters:
  /// - [json] - Raw JSON response from Energy Star API
  /// - [datasetId] - Optional dataset identifier for appliance type lookup
  factory EnergyStarNormalizedData.fromJson(Map<String, dynamic> json,
      [String? datasetId]) {
    // Extract common fields with fallback names
    final brandName = _extractField<String?>(json, _brandNameFields);
    final modelNumber = _extractField<String?>(json, _modelNumberFields);

    // Extract energy consumption with various field names
    final energyUse =
        _extractField<double>(json, _energyFields, asDouble: true);

    // Find appliance type by checking which type uses this dataset ID
    String? applianceTypeName;
    for (final type in ApplianceInfo.values) {
      if (type.datasetIds.contains(datasetId)) {
        applianceTypeName = type.name;
        break;
      }
    }

    return EnergyStarNormalizedData(
      brandName: brandName,
      modelNumber: modelNumber,
      annualEnergyUseKwhPerYear: energyUse,
      additionalFields: json,
      datasetId: datasetId ?? '',
      applianceType: applianceTypeName,
    );
  }

  /// Field name lists for common data extraction patterns
  static const _brandNameFields = [
    'brand_name',
    'outdoor_unit_brand_name',
    'manufacturer',
    'brand'
  ];

  static const _modelNumberFields = [
    'model_number',
    'indoor_unit_model_number',
    'model',
    'model_name'
  ];

  static const _energyFields = [
    'annual_energy_use_kwh_yr',
    'annual_energy_consumption_kwh_yr',
    'annual_energy_use_kwh_year',
    'energy_use_kwh_year',
    'annual_energy_consumption',
    'energy_consumption'
  ];

  /// Extracts a field value from JSON using multiple possible field names.
  ///
  /// Different Energy Star datasets use different field naming conventions.
  /// This method tries each field name in order and returns the first non-null match,
  /// with automatic type conversion based on the desired return type.
  ///
  /// Type Parameters:
  /// - [T] - Return type (String?, double, etc.)
  ///
  /// Parameters:
  /// - [json] - JSON object to search
  /// - [fieldNames] - List of possible field names to try in order
  /// - [asDouble] - If true, extracts and converts to double; if false, converts to string (default: false)
  ///
  /// Returns:
  /// - For strings (asDouble=false): First non-null value converted to string, or null if not found
  /// - For doubles (asDouble=true): First parseable numeric value as double, or 0.0 if not found
  static T _extractField<T>(
    Map<String, dynamic> json,
    List<String> fieldNames, {
    bool asDouble = false,
  }) {
    for (final field in fieldNames) {
      final value = json[field];

      if (value == null) continue;
      if (!asDouble) return value.toString() as T;

      final numValue = value is num ? value : double.tryParse(value.toString());

      if (numValue != null) return numValue.toDouble() as T;
    }

    return (asDouble ? 0.0 : null) as T;
  }

  /// Converts the normalized data back to JSON format.
  /// Includes both the normalized fields and all additional raw fields
  /// from the original API response.
  Map<String, dynamic> toJson() {
    return {
      'brand_name': brandName,
      'model_number': modelNumber,
      'annual_energy_use_kwh_year': annualEnergyUseKwhPerYear,
      'dataset_id': datasetId,
      'appliance_type': applianceType,
      ...additionalFields,
    };
  }
}
