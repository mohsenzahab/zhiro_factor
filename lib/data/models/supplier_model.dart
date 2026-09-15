import 'package:equatable/equatable.dart';

/// Supplier (تأمین‌کننده) data model.
class SupplierModel extends Equatable {
  final int? id;
  final String? code;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;

  const SupplierModel({
    this.id,
    this.code,
    required this.name,
    this.phone,
    this.address,
    this.notes,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as int?,
      code: map['code'] as String?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    };
  }

  SupplierModel copyWith({
    int? id,
    String? code,
    String? name,
    String? phone,
    String? address,
    String? notes,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, code, name, phone, address, notes];
}
