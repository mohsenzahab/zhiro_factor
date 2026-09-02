import 'package:equatable/equatable.dart';

/// Customer data model.
class CustomerModel extends Equatable {
  final int? id;
  final String? code;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;

  const CustomerModel({
    this.id,
    this.code,
    required this.name,
    this.phone,
    this.address,
    this.notes,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
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

  CustomerModel copyWith({
    int? id,
    String? code,
    String? name,
    String? phone,
    String? address,
    String? notes,
  }) {
    return CustomerModel(
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
