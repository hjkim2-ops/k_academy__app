import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String childName;

  @HiveField(2)
  final DateTime paymentDate;

  @HiveField(3)
  final String businessName;

  @HiveField(4)
  final String subject;

  @HiveField(5)
  final String instructor;

  @HiveField(6)
  final String detail;

  @HiveField(7)
  final String classType; // 현강 or 라이브

  @HiveField(8)
  final String paymentMethod;

  @HiveField(9)
  final String? cardName;

  @HiveField(10)
  final int amount;

  @HiveField(11)
  final int cancellationAmount;

  @HiveField(12)
  final bool isRefunded;

  @HiveField(13)
  final String? memo;

  Expense({
    required this.id,
    required this.childName,
    required this.paymentDate,
    required this.businessName,
    required this.subject,
    required this.instructor,
    required this.detail,
    required this.classType,
    required this.paymentMethod,
    this.cardName,
    required this.amount,
    required this.cancellationAmount,
    required this.isRefunded,
    this.memo,
  });

  // Firestore 직렬화
  Map<String, dynamic> toMap() {
    return {
      'childName': childName,
      'paymentDate': paymentDate.toIso8601String(),
      'businessName': businessName,
      'subject': subject,
      'instructor': instructor,
      'detail': detail,
      'classType': classType,
      'paymentMethod': paymentMethod,
      'cardName': cardName,
      'amount': amount,
      'cancellationAmount': cancellationAmount,
      'isRefunded': isRefunded,
      'memo': memo,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      childName: map['childName'] ?? '',
      paymentDate: DateTime.parse(map['paymentDate']),
      businessName: map['businessName'] ?? '',
      subject: map['subject'] ?? '',
      instructor: map['instructor'] ?? '',
      detail: map['detail'] ?? '',
      classType: map['classType'] ?? '현강',
      paymentMethod: map['paymentMethod'] ?? '',
      cardName: map['cardName'],
      amount: map['amount'] ?? 0,
      cancellationAmount: map['cancellationAmount'] ?? 0,
      isRefunded: map['isRefunded'] ?? false,
      memo: map['memo'],
    );
  }

  // dateKey getter for calendar grouping (normalized to midnight)
  DateTime get dateKey => DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );

  // Copy with method for updates
  Expense copyWith({
    String? id,
    String? childName,
    DateTime? paymentDate,
    String? businessName,
    String? subject,
    String? instructor,
    String? detail,
    String? classType,
    String? paymentMethod,
    String? cardName,
    int? amount,
    int? cancellationAmount,
    bool? isRefunded,
    String? memo,
  }) {
    return Expense(
      id: id ?? this.id,
      childName: childName ?? this.childName,
      paymentDate: paymentDate ?? this.paymentDate,
      businessName: businessName ?? this.businessName,
      subject: subject ?? this.subject,
      instructor: instructor ?? this.instructor,
      detail: detail ?? this.detail,
      classType: classType ?? this.classType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardName: cardName ?? this.cardName,
      amount: amount ?? this.amount,
      cancellationAmount: cancellationAmount ?? this.cancellationAmount,
      isRefunded: isRefunded ?? this.isRefunded,
      memo: memo ?? this.memo,
    );
  }
}
