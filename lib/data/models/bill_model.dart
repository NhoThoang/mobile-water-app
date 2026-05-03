class Bill {
  final int id;
  final String month;
  final double consumption;
  final double totalAmount;
  final String status;
  final DateTime dueDate;

  Bill({
    required this.id,
    required this.month,
    required this.consumption,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      month: json['month'],
      consumption: (json['consumption'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      dueDate: DateTime.parse(json['due_date']),
    );
  }
}
