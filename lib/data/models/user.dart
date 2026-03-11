class User {
  final int? id;
  final String? username;
  final String? email;
  final String? provider;
  final bool? confirmed;
  final bool? blocked;
  final String? role;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    this.username,
    this.email,
    this.provider,
    this.confirmed,
    this.blocked,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? roleName;
    if (json['role'] != null) {
      if (json['role'] is Map) {
        roleName = json['role']['name']?.toString() ?? json['role']['type']?.toString();
      } else {
        roleName = json['role'].toString();
      }
    }

    if (!json.containsKey('_printed_keys_dev_')) {
      print('USER KEYS: ${json.keys.toList()}');
      json['_printed_keys_dev_'] = true;
    }

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      provider: json['provider'],
      confirmed: json['confirmed'],
      blocked: json['blocked'],
      role: roleName,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'provider': provider,
      'confirmed': confirmed,
      'blocked': blocked,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
