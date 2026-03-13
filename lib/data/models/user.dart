class User {
  final int? id;
  final String? username;
  final String? email;
  final String? provider;
  final bool? confirmed;
  final bool? blocked;
  final dynamic role; // Peut être une chaîne, un ID ou un Objet Map complet
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

  /// Nom affiché du rôle (ex: "Administrateur", "Authenticated")
  String get roleName {
    if (role == null) return '';
    if (role is Map) return (role['name'] ?? role['type'] ?? '').toString();
    return role.toString();
  }

  /// Type de rôle utile pour le code et les permissions (miniscules, sans espaces ex: "admin", "space_manager")
  String get roleType {
    if (role == null) return '';
    if (role is Map) return (role['type'] ?? role['name'] ?? '').toString().toLowerCase();
    return role.toString().toLowerCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('_printed_keys_dev_')) {
      print('USER KEYS: ${json.keys.toList()}');
      json['_printed_keys_dev_'] = true;
    }
//créer un objet User depuis JSON
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      provider: json['provider'],
      confirmed: json['confirmed'],
      blocked: json['blocked'],
      role: json['role'], // On garde le rôle tel qu’il vient du backend (Strapi)
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
//transformer l’objet User en JSON
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
