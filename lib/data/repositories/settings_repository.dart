import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/date_range_filter_bar.dart';
import '../models/business_settings_model.dart';

/// Repository for persisting business settings via SharedPreferences.
class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  // SharedPreferences keys
  static const String _keyBusinessName = 'settings_business_name';
  static const String _keyDescription = 'settings_description';
  static const String _keyShowName = 'settings_show_name_on_invoice';
  static const String _keyShowDescription = 'settings_show_description_on_invoice';
  static const String _keyDescriptionPosition = 'settings_description_position';
  static const String _keyDefaultPageFormat = 'settings_default_page_format';

  /// Load saved business settings.
  Future<BusinessSettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessSettingsModel(
      businessName: prefs.getString(_keyBusinessName) ?? '',
      description: prefs.getString(_keyDescription) ?? '',
      showNameOnInvoice: prefs.getBool(_keyShowName) ?? true,
      showDescriptionOnInvoice: prefs.getBool(_keyShowDescription) ?? true,
      descriptionPosition: prefs.getString(_keyDescriptionPosition) ?? 'bottom',
      defaultPageFormat: prefs.getString(_keyDefaultPageFormat) ?? 'a4',
    );
  }

  /// Save business settings.
  Future<void> saveSettings(BusinessSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBusinessName, settings.businessName);
    await prefs.setString(_keyDescription, settings.description);
    await prefs.setBool(_keyShowName, settings.showNameOnInvoice);
    await prefs.setBool(_keyShowDescription, settings.showDescriptionOnInvoice);
    await prefs.setString(_keyDescriptionPosition, settings.descriptionPosition);
    await prefs.setString(_keyDefaultPageFormat, settings.defaultPageFormat);
  }

  /// Quick read of business name only (for sidebar display).
  Future<String> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBusinessName) ?? '';
  }

  // Dashboard filter keys
  static const String _keyDashboardFilterPreset = 'dashboard_filter_preset';
  static const String _keyDashboardFilterCategory = 'dashboard_filter_category';
  static const String _keyDashboardFilterCustomFrom = 'dashboard_filter_custom_from';
  static const String _keyDashboardFilterCustomTo = 'dashboard_filter_custom_to';

  /// Load saved dashboard filter preferences.
  Future<DashboardFilterPreference> loadDashboardFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final presetName = prefs.getString(_keyDashboardFilterPreset);
    DateRangePreset preset = DateRangePreset.thisMonth;
    if (presetName != null) {
      for (final p in DateRangePreset.values) {
        if (p.name == presetName) {
          preset = p;
          break;
        }
      }
    }
    final category = prefs.getString(_keyDashboardFilterCategory);
    final customFrom = prefs.getString(_keyDashboardFilterCustomFrom);
    final customTo = prefs.getString(_keyDashboardFilterCustomTo);

    return DashboardFilterPreference(
      preset: preset,
      customDateFrom: customFrom,
      customDateTo: customTo,
      category: category,
    );
  }

  /// Save dashboard filter preferences.
  Future<void> saveDashboardFilter({
    required DateRangePreset preset,
    String? customDateFrom,
    String? customDateTo,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDashboardFilterPreset, preset.name);
    if (category != null && category.isNotEmpty) {
      await prefs.setString(_keyDashboardFilterCategory, category);
    } else {
      await prefs.remove(_keyDashboardFilterCategory);
    }
    if (customDateFrom != null && customDateFrom.isNotEmpty) {
      await prefs.setString(_keyDashboardFilterCustomFrom, customDateFrom);
    } else {
      await prefs.remove(_keyDashboardFilterCustomFrom);
    }
    if (customDateTo != null && customDateTo.isNotEmpty) {
      await prefs.setString(_keyDashboardFilterCustomTo, customDateTo);
    } else {
      await prefs.remove(_keyDashboardFilterCustomTo);
    }
  }
}

/// Preferences for dashboard date and category filters.
class DashboardFilterPreference {
  final DateRangePreset preset;
  final String? customDateFrom;
  final String? customDateTo;
  final String? category;

  const DashboardFilterPreference({
    this.preset = DateRangePreset.thisMonth,
    this.customDateFrom,
    this.customDateTo,
    this.category,
  });
}
