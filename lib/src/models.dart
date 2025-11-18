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
    final brandName = _extractField(json,
        ['brand_name', 'outdoor_unit_brand_name', 'manufacturer', 'brand']);

    final modelNumber = _extractField(json,
        ['model_number', 'indoor_unit_model_number', 'model', 'model_name']);

    // Extract energy consumption with various field names
    final energyUse = _extractEnergyField(json);

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

  /// Extracts a field value from JSON using multiple possible field names.
  ///
  /// Different Energy Star datasets use different field naming conventions.
  /// This method tries each field name in order and returns the first match.
  ///
  /// Parameters:
  /// - [json] - JSON object to search
  /// - [fieldNames] - List of possible field names to try
  ///
  /// Returns the field value as a string, or null if not found.
  static String? _extractField(
      Map<String, dynamic> json, List<String> fieldNames) {
    for (final field in fieldNames) {
      if (json.containsKey(field) && json[field] != null) {
        return json[field].toString();
      }
    }
    return null;
  }

  /// Extracts annual energy consumption from JSON using multiple field names.
  /// Tries various field name variations and handles both numeric and string values.
  ///
  /// Parameters:
  /// - [json] - JSON object containing energy data
  ///
  /// Returns energy consumption in kWh/year, or 0.0 if not found.
  static double _extractEnergyField(Map<String, dynamic> json) {
    final energyFields = [
      'annual_energy_use_kwh_yr',
      'annual_energy_consumption_kwh_yr',
      'annual_energy_use_kwh_year',
      'energy_use_kwh_year',
      'annual_energy_consumption',
      'energy_consumption'
    ];

    for (final field in energyFields) {
      if (json.containsKey(field) && json[field] != null) {
        final value = json[field];
        if (value is num)
          return value.toDouble();
        else if (value is String) return double.tryParse(value) ?? 0.0;
      }
    }
    return 0.0;
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
