class Expense {
  final int? id;
  final int? vehicleId;
  final String type;
  final double amount;
  final double? odometerReading;
  final DateTime expenseDate;
  final String? description;
  final String? serviceProvider;
  final String? invoiceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    this.id,
    this.vehicleId,
    required this.type,
    required this.amount,
    this.odometerReading,
    required this.expenseDate,
    this.description,
    this.serviceProvider,
    this.invoiceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    int? id,
    int? vehicleId,
    String? type,
    double? amount,
    double? odometerReading,
    DateTime? expenseDate,
    String? description,
    String? serviceProvider,
    String? invoiceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      odometerReading: odometerReading ?? this.odometerReading,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'amount': amount,
      'odometer_reading': odometerReading,
      'expense_date': expenseDate.toIso8601String(),
      'description': description,
      'service_provider': serviceProvider,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int?,
      type: map['type'] as String? ?? 'miscellaneous',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      odometerReading: (map['odometer_reading'] as num?)?.toDouble(),
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'] as String)
          : DateTime.now(),
      description: map['description'] as String?,
      serviceProvider: map['service_provider'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
