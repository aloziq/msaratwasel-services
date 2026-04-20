import 'package:equatable/equatable.dart';

class BusExpense extends Equatable {
  final int id;
  final int busId;
  final String type;
  final double amount;
  final DateTime date;
  final String? extraInfo;
  final String? receiptPhoto;

  const BusExpense({
    required this.id,
    required this.busId,
    required this.type,
    required this.amount,
    required this.date,
    this.extraInfo,
    this.receiptPhoto,
  });

  @override
  List<Object?> get props => [id, busId, type, amount, date, extraInfo, receiptPhoto];
}
