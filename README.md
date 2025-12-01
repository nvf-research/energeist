# Energeist
A Dart subsystem for energy consumption estimation and tracking of household appliances using Energy Star data. Energeist provides a simple interface to fetch appliance data from the Energy Star API and estimate energy usage based on appliance type, brand name, and model number.

## Features
- Query Energy Star API for appliance energy consumption data
- Support multiple appliance types
- Estimate energy usage from minimal inputs (appliance type, brand name, model number)
- Choose between median or mean aggregation strategies
- Normalized data model that standardizes various Energy Star dataset formats
- Handles multiple dataset IDs per appliance type

## Installation
Add this to your package's `pubspec.yaml` file:

### Option 1: Use a Specific Version (Recommended)
```yaml
dependencies:
  energeist:
    git:
      url: https://github.com/nvf-research/energeist.git
      ref: v0.2.0
```

### Option 2: Use Latest from Main Branch
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
The simplest way to use Energeist is with the `Estimator` class to get energy usage for an appliance:

```dart
import 'package:energeist/energeist.dart';

void main() async {
  final estimator = Estimator();

  // Use Case 1: Estimate for all refrigerators (defaults to median)
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

  // Use Case 4: Use mean instead of median
  final meanEstimate = await estimator.estimate(
    type: ApplianceInfo.refrigerator,
    brandName: 'Lynx',
    modelNumber: 'LN24REFC*',
    strategy: Strategy.mean,
  );
}
```

### Advanced: Direct Energy Star API Queries
For more control, use the `EnergyStarService` to query the Energy Star API directly:

```dart
import 'package:energeist/energeist.dart';

void main() async {
  final service = EnergyStarService();

  // Search for all Lynx refrigerators
  final results = await service.fetchAppliances(
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
- `datasetIds`: Energy Star dataset IDs to query
- `energyStarFieldNames`: Expected field names in API responses

## API Reference
### Estimator
Estimates appliance energy consumption from minimal inputs.

**Methods:**
- `estimate({required ApplianceInfo type, String? brandName, String? modelNumber, Strategy strategy = Strategy.median})`: Returns aggregated annual energy usage in kWh/year based on the chosen strategy (median or mean)

### EnergyStarService
Service for interacting with the Energy Star API.

**Methods:**
- `fetchAppliances({required Set<String> datasetIds, String? brandName, String? modelNumber})`: Returns a list of normalized appliance data fetched in parallel from the Energy Star datasets.

### EnergyStarNormalizedData
Normalized data model for Energy Star API responses.

**Properties:**
- `brandName`: Brand name of the appliance
- `modelNumber`: Model number
- `annualEnergyUseKwhPerYear`: Annual energy consumption
- `datasetId`: Energy Star dataset ID
- `applianceType`: Type of appliance
- `additionalFields`: Raw API response data

**Methods:**
- `fromJson(Map<String, dynamic> json, [String? datasetId])`: Converts raw Energy Star API responses into a standardized format
- `toJson()`: Converts the normalized object back to JSON format

## How It Works
1. **Data Source**: Energeist queries the Energy Star public API, which contains certified appliance data
2. **Normalization**: Different Energy Star datasets use different field names. Energeist normalizes these into a consistent format
3. **Estimation**: When estimating energy usage, Energeist:
   - Queries the appropriate Energy Star dataset(s) for the appliance type
   - Filters by brand and/or model if provided
   - Calculates the median or mean energy consumption from all matching results (defaults to median)
   - Returns 0.0 if no matches are found

### Aggregation Strategies
Energeist supports two aggregation strategies:
- **Strategy.median** (default): Returns the middle value, less affected by outliers
- **Strategy.mean**: Returns the average value, useful for understanding typical consumption across all models
