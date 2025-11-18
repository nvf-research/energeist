/// Appliance types supported by the subsystem with Energy Star metadata.
/// Each enum value represents a specific appliance category with associated
/// Energy Star dataset IDs and field mappings. Used to query the Energy Star
/// API and retrieve appliance energy consumption data.
enum ApplianceInfo {
  refrigerator(
    displayName: 'Refrigerator',
    datasetIds: {'p5st-her9', 'hgxv-ux9b'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
      'height_in',
      'width_in',
    },
  ),
  freezer(
    displayName: 'Freezer',
    datasetIds: {'8t9c-g3tn', 'teze-bgsr'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
    },
  ),
  dishwasher(
    displayName: 'Dishwasher',
    datasetIds: {'q8py-6w3f', 'butk-3ni4'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
      'width_inches',
      'depth_inches',
    },
  ),
  clothWasher(
    displayName: 'Clothes Washer',
    datasetIds: {'bghd-e2wd', 'd36s-eh9f'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
      'height_inches',
      'width_inches',
      'depth_inches',
    },
  ),
  clothDryer(
    displayName: 'Clothes Dryer',
    datasetIds: {'t9u7-4d2j'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'estimated_annual_energy_use_kwh_yr',
    },
  ),
  waterHeater(
    displayName: 'Water Heater',
    datasetIds: {'xmq6-bm79'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
      'storage_volume_gallons',
      'tank_height_inches',
      'height_to_vent_inches',
      'vent_size_inches',
      'standby_loss',
      'input_rate_thousand_btu_per_hour'
    },
  ),
  centralAc(
    displayName: 'Central AC',
    datasetIds: {'s4ew-vcih'},
    energyStarFieldNames: {
      'outdoor_unit_brand_name',
      'model_number',
      'cooling_capacity_btu_h',
    },
  ),
  roomAc(
    displayName: 'Room AC',
    datasetIds: {'5xn2-dv4h', 'irdz-jn2s'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
      'height_in',
      'width_in',
      'depth_in',
    },
  ),
  dehumidifier(
    displayName: 'Dehumidifier',
    datasetIds: {'mgiu-hu4z', 'b88x-mifp'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_use_kwh_yr',
    },
  ),
  ceilingFan(
    displayName: 'Ceiling Fan',
    datasetIds: {'2te3-nmxp', 'ufj6-xsix'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'ceiling_fan_size_diameters_in_inches',
      'fan_power_consumption_high_speed_w',
      'fan_power_consumption_standby_w',
    },
  ),
  computerMonitor(
    displayName: 'Computer Monitor',
    datasetIds: {'a437-vvgv'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'screen_size_inches',
      'on_mode_power_watts',
      'off_mode_power_watts',
    },
  ),
  display(
    displayName: 'Display',
    datasetIds: {'qbg3-d468'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'screen_size_inches',
      'on_mode_power_watts',
      'off_mode_power_watts',
    },
  ),
  electricCookingProduct(
    displayName: 'Electric Cooking Product',
    datasetIds: {'m6gi-ng33'},
    energyStarFieldNames: {
      'brand_name',
      'model_number',
      'annual_energy_consumption_kwh_yr',
      'height_inches',
      'width_inches',
      'depth_inches',
    },
  );

  /// Creates an appliance info instance with metadata.
  ///
  /// Parameters:
  /// - [displayName] - Human-readable name (e.g., "Refrigerator")
  /// - [datasetIds] - Energy Star dataset IDs to query for this appliance type
  /// - [energyStarFieldNames] - Expected field names in API responses
  const ApplianceInfo({
    required this.displayName,
    required this.datasetIds,
    this.energyStarFieldNames = const {},
  });

  final String displayName;
  final Set<String> datasetIds;
  final Set<String> energyStarFieldNames;

  /// Returns the display name when converted to string.
  @override
  String toString() => displayName;
}
