class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String userID;
  String? profileImage;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.userID,
    this.profileImage,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['_id'] ?? json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      userID: json['userID'] ?? '',
      profileImage: json['profileImage'],
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'username': username,
      'userID': userID,
      'profileImage': profileImage,
      'token': token,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? userID,
    String? imageUrl,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      userID: userID ?? this.userID,
      profileImage: imageUrl ?? this.profileImage,
      token: token ?? this.token,
    );
  }
}
