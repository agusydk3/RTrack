class ShippingStatus {
  final String message;
  final String dateTime;
  final bool isCompleted;

  ShippingStatus({
    required this.message,
    required this.dateTime,
    required this.isCompleted,
  });
}

class ShippingData {
  final String id;
  final String title;
  final String status;
  final String date;
  final String updated;
  final String shipper;
  final String receiver;
  final String courier;
  final List<ShippingStatus> trackingHistory;

  ShippingData({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.updated,
    required this.shipper,
    required this.receiver,
    required this.courier,
    required this.trackingHistory,
  });
}
