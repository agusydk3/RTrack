class CourierConstants {
  static const Map<String, String> courierNames = {
    'jne': 'JNE',
    'jnt': 'J&T Express',
    'pos': 'POS Indonesia',
    'sicepat': 'SiCepat',
    'anteraja': 'AnterAja',
    'tiki': 'TIKI',
    'spx': 'Shopee Express'
  };

  static String getCourierName(String code) {
    return courierNames[code.toLowerCase()] ?? code;
  }
}
