# Energeist
A Dart subsystem for energy consumption estimation and tracking of household appliances using EnergyStar data. Energeist provides a simple interface to fetch appliance data from the EnergyStar API and estimate energy usage based on appliance type, brand name, and model number.

## Features
- Query EnergyStar API for appliance energy consumption data
- Support multiple appliance types
- Estimate median energy usage from minimal inputs (appliance type, brand name, model number)
- Normalized data model that standardizes various EnergyStar dataset formats
- Handles multiple dataset IDs per appliance type

## Installation
Add this to your package's `pubspec.yaml` file:
```yaml
dependencies:
  energeist:
    git:
      url: https://github.com/nvf-research/energeist.git
      ref: main
```

Then run:
```bash
dart pub get
```

## Usage
### Basic Energy Estimation
The simplest way to use Energeist is with the `Estimator` class to get median energy usage for an appliance:

```dart
import 'package:energeist/energeist.dart';

void main() async {
  final estimator = Estimator();

  // Use Case 1: Estimate for all refrigerators
  final estimatesForRefrigerators = await estimator.estimate(
    type: ApplianceInfo.refrigerator,
  );

  // Use Case 2: Estimate for a specific brand
  final estimatesForRefrigeratorsBrand = await estimator.estimate(
    type: ApplianceInfo.refrigerator,
    brandName: 'Lynx',
  );

  // Use Case 3: Estimate for a specific brand and model
  final estimatesForRefrigeratorsBrandAndModel = await estimator.estimate(
    type: ApplianceInfo.refrigerator,
    brandName: 'Lynx',
    modelNumber: 'LN24REFC*',
  );
}
```

### Advanced: Direct EnergyStar API Queries
For more control, use the `EnergyStarService` to query the EnergyStar API directly:

```dart
import 'package:energeist/energeist.dart';

void main() async {
  final service = EnergyStarService();

  // Search for all Lynx refrigerators
  final results = await service.searchByDatasetIds(
    datasetIds: ApplianceInfo.refrigerator.datasetIds,
    brandName: 'Lynx',
  );

  for (final appliance in results) {
    print('Brand: ${appliance.brandName}');
    print('Model: ${appliance.modelNumber}');
    print('Energy: ${appliance.annualEnergyUseKwhPerYear} kWh/year');
  }
}
```

### Available Appliance Types
Use the `ApplianceInfo` enum to specify appliance types:

```dart
ApplianceInfo.refrigerator
ApplianceInfo.freezer
ApplianceInfo.dishwasher
ApplianceInfo.clothWasher
ApplianceInfo.clothDryer
ApplianceInfo.waterHeater
ApplianceInfo.centralAc
ApplianceInfo.roomAc
ApplianceInfo.dehumidifier
ApplianceInfo.ceilingFan
ApplianceInfo.computerMonitor
ApplianceInfo.display
ApplianceInfo.electricCookingProduct
```

Each appliance type contains:
- `displayName`: Human-readable, appliance name
- `datasetIds`: EnergyStar dataset IDs to query
- `energyStarFieldNames`: Expected field names in API responses

## API Reference
### Estimator
Estimates appliance energy consumption from minimal inputs.

**Methods:**
- `estimate({required ApplianceInfo type, String? brandName, String? modelNumber})`: Returns median annual energy usage in kWh/year

### EnergyStarService
Service for interacting with the EnergyStar API.

**Methods:**
- `searchByDatasetIds({required Set<String> datasetIds, String? brandName, String? modelNumber, Map<String, String>? additionalFilters})`: Returns a list of normalized appliance data

### EnergyStarNormalizedData
Normalized data model for EnergyStar API responses.

**Properties:**
- `brandName`: Brand name of the appliance
- `modelNumber`: Model number
- `annualEnergyUseKwhPerYear`: Annual energy consumption
- `datasetId`: EnergyStar dataset ID
- `applianceType`: Type of appliance
- `additionalFields`: Raw API response data

**Methods:**
- `fromJson(Map<String, dynamic> json, [String? datasetId])`: Converts raw EnergyStar API responses into a standardized format
- `toJson()`: Converts the normalized object back to JSON format

## How It Works
1. **Data Source**: Energeist queries the EnergyStar public API, which contains certified appliance data
2. **Normalization**: Different EnergyStar datasets use different field names. Energeist normalizes these into a consistent format
3. **Estimation**: When estimating energy usage, Energeist:
   - Queries the appropriate EnergyStar dataset(s) for the appliance type
   - Filters by brand and/or model if provided
   - Calculates the median energy consumption from all matching results
   - Returns 0.0 if no matches are found
