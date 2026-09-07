import 'package:equatable/equatable.dart';

/// A single item within a preset template.
class PresetTemplateItem extends Equatable {
  final int? id;
  final int? templateId;
  final int? productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  const PresetTemplateItem({
    this.id,
    this.templateId,
    this.productId,
    required this.productName,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (templateId != null) 'template_id': templateId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  factory PresetTemplateItem.fromMap(Map<String, dynamic> map) {
    return PresetTemplateItem(
      id: map['id'] as int?,
      templateId: map['template_id'] as int?,
      productId: map['product_id'] as int?,
      productName: (map['product_name'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PresetTemplateItem copyWith({
    int? id,
    int? templateId,
    int? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
  }) {
    return PresetTemplateItem(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [id, templateId, productId, productName, quantity, unitPrice];
}

/// A preset template (pre-invoice) containing a named list of items.
class PresetTemplateModel extends Equatable {
  final int? id;
  final String name;
  final String? createdAt;
  final List<PresetTemplateItem> items;

  const PresetTemplateModel({
    this.id,
    required this.name,
    this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };

  factory PresetTemplateModel.fromMap(Map<String, dynamic> map,
      {List<PresetTemplateItem> items = const []}) {
    return PresetTemplateModel(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      createdAt: map['created_at'] as String?,
      items: items,
    );
  }

  PresetTemplateModel copyWith({
    int? id,
    String? name,
    String? createdAt,
    List<PresetTemplateItem>? items,
  }) {
    return PresetTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, items];
}
