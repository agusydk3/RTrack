class Resi {
  final String id;
  final String noResi;
  final String title;
  final String courier;
  final DateTime createdAt;

  Resi({
    required this.id,
    required this.noResi,
    required this.title,
    required this.courier,
    required this.createdAt,
  });

  factory Resi.fromJson(Map<String, dynamic> json) {
    return Resi(
      id: json['_id'] ?? '',
      noResi: json['noResi'] ?? '',
      title: json['title'] ?? '',
      courier: json['courier'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noResi': noResi,
      'title': title,
      'courier': courier,
    };
  }
}
