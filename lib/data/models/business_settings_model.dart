/// Model for storing business profile settings.
class BusinessSettingsModel {
  final String businessName;
  final String description;
  final bool showNameOnInvoice;
  final bool showDescriptionOnInvoice;

  /// Where the description block is placed on the invoice.
  /// `top` = below business name in the header.
  /// `bottom` = after the totals section at the end.
  final String descriptionPosition; // 'top' | 'bottom'

  const BusinessSettingsModel({
    this.businessName = '',
    this.description = '',
    this.showNameOnInvoice = true,
    this.showDescriptionOnInvoice = true,
    this.descriptionPosition = 'top',
  });

  /// Whether any business info should be shown on the invoice.
  bool get hasAnyInvoiceInfo =>
      (showNameOnInvoice && businessName.isNotEmpty) ||
      (showDescriptionOnInvoice && description.isNotEmpty);

  BusinessSettingsModel copyWith({
    String? businessName,
    String? description,
    bool? showNameOnInvoice,
    bool? showDescriptionOnInvoice,
    String? descriptionPosition,
  }) {
    return BusinessSettingsModel(
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      showNameOnInvoice: showNameOnInvoice ?? this.showNameOnInvoice,
      showDescriptionOnInvoice: showDescriptionOnInvoice ?? this.showDescriptionOnInvoice,
      descriptionPosition: descriptionPosition ?? this.descriptionPosition,
    );
  }
}
