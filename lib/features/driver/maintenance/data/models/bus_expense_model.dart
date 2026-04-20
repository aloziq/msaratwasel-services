import '../../domain/entities/bus_expense.dart';

class BusExpenseModel extends BusExpense {
  const BusExpenseModel({
    required super.id,
    required super.busId,
    required super.type,
    required super.amount,
    required super.date,
    super.extraInfo,
    super.receiptPhoto,
  });

  factory BusExpenseModel.fromJson(Map<String, dynamic> json) {
    return BusExpenseModel(
      id: json['id'],
      busId: json['bus_id'],
      type: json['type'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      extraInfo: json['extra_info'],
      receiptPhoto: json['receipt_photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_id': busId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'extra_info': extraInfo,
      'receipt_photo': receiptPhoto,
    };
  }
}
