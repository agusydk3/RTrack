import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipping.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';

class ShippingService {
  static const String baseUrl = 'https://api.binderbyte.com/v1/track';
  static const String apiKey = ApiConfig.binderByteApiKey;
  
  static const Map<String, String> courierNames = {
    'jnt': 'J&T Express',
    'jne': 'JNE Express',
    'sicepat': 'SiCepat Express',
    'anteraja': 'AnterAja',
    'pos': 'POS Indonesia',
  };

  static Future<ShippingData> trackShipment(String trackingNumber, String courier, {String? title}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?api_key=$apiKey&courier=$courier&awb=$trackingNumber'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Nomor resi tidak ditemukan atau tidak sesuai dengan kurir yang dipilih');
      }

      final jsonData = json.decode(response.body);
      
      if (jsonData['status'] != 200) {
        throw Exception('Nomor resi tidak ditemukan atau tidak sesuai dengan kurir yang dipilih');
      }

      final data = jsonData['data'];
      final summary = data['summary'] as Map<String, dynamic>;
      final detail = data['detail'] as Map<String, dynamic>;
      final history = data['history'] as List<dynamic>;

      // Convert history items to TrackingStatus objects
      final trackingHistory = history.map((item) {
        final date = item['date'] as String;
        final desc = item['desc'] as String;
        final location = item['location'] as String? ?? '';

        return ShippingStatus(
          dateTime: date,
          message: '$desc ${location.isNotEmpty ? "($location)" : ""}',
          isCompleted: desc.toUpperCase().contains('DELIVERED'),
        );
      }).toList();

      final summaryDate = summary['date'] as String? ?? DateTime.now().toString();

      return ShippingData(
        id: trackingNumber,
        title: title?.isNotEmpty == true ? title! : 'Shipment $trackingNumber',
        courier: summary['courier'] ?? courierNames[courier] ?? courier.toUpperCase(),
        status: summary['status']?.toString().toUpperCase() ?? 'PENDING',
        date: summaryDate,
        updated: summaryDate,
        shipper: detail['shipper']?.toString().trim().isEmpty == false ? detail['shipper'].toString() : '******',
        receiver: detail['receiver']?.toString().trim().isEmpty == false ? detail['receiver'].toString() : '******',
        trackingHistory: trackingHistory,
      );
    } catch (e) {
      print('Error tracking shipment: $e');
      throw Exception('Nomor resi tidak ditemukan atau tidak sesuai dengan kurir yang dipilih');
    }
  }
}
