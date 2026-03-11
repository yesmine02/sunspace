class Association {
  final int? id;
  final String? documentId;
  final String name;
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final double budget;
  final bool isVerified;
  final AssociationAdmin? admin;
  final List<dynamic>? members;

  Association({
    this.id,
    this.documentId,
    required this.name,
    this.description,
    this.email,
    this.phone,
    this.website,
    this.budget = 0.0,
    this.isVerified = false,
    this.admin,
    this.members,
  });

  factory Association.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return Association(
      id: data['id'] is int ? data['id'] : null,
      documentId: data['documentId'],
      name: data['name'] ?? '',
      description: data['description'],
      email: data['email'],
      phone: data['phone'],
      website: data['website'],
      budget: (data['budget'] ?? 0.0).toDouble(),
      isVerified: data['is_verified'] ?? false,
      admin: data['admin'] != null ? AssociationAdmin.fromJson(data['admin']) : null,
      members: data['members'] is List ? data['members'] : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
      'website': website,
      'budget': budget,
      'is_verified': isVerified,
    };
  }
}

class AssociationAdmin {
  final int? id;
  final String? username;
  final String? email;

  AssociationAdmin({this.id, this.username, this.email});

  factory AssociationAdmin.fromJson(Map<String, dynamic> json) {
    return AssociationAdmin(
      id: json['id'] is int ? json['id'] : null,
      username: json['username'],
      email: json['email'],
    );
  }
}
