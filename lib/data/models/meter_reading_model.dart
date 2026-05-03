class MeterReading {
  final int id;
  final int customerId;
  final double reading;
  final double previousReading;
  final double consumption;
  final String month;
  final String? imageUrl;
  final String? note;
  final bool isAnomaly;
  final DateTime createdAt;

  MeterReading({
    required this.id,
    required this.customerId,
    required this.reading,
    required this.previousReading,
    required this.consumption,
    required this.month,
    this.imageUrl,
    this.note,
    required this.isAnomaly,
    required this.createdAt,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    return MeterReading(
      id: json['id'],
      customerId: json['customer_id'],
      reading: (json['reading'] as num).toDouble(),
      previousReading: (json['previous_reading'] as num).toDouble(),
      consumption: (json['consumption'] as num).toDouble(),
      month: json['month'],
      imageUrl: json['image_url'],
      note: json['note'],
      isAnomaly: json['is_anomaly'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
