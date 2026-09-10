import 'package:shared_preferences/shared_preferences.dart';
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

  /// Load saved business settings.
  Future<BusinessSettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessSettingsModel(
      businessName: prefs.getString(_keyBusinessName) ?? '',
      description: prefs.getString(_keyDescription) ?? '',
      showNameOnInvoice: prefs.getBool(_keyShowName) ?? true,
      showDescriptionOnInvoice: prefs.getBool(_keyShowDescription) ?? true,
      descriptionPosition: prefs.getString(_keyDescriptionPosition) ?? 'top',
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
  }

  /// Quick read of business name only (for sidebar display).
  Future<String> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBusinessName) ?? '';
  }
}
