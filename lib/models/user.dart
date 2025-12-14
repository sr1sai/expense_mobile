class UserPublicDTO {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  UserPublicDTO({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory UserPublicDTO.fromJson(Map<String, dynamic> json) {
    return UserPublicDTO(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phoneNumber': phoneNumber,
  };
}

class UserDTO {
  final String name;
  final String email;
  final String password;
  final String phoneNumber;

  UserDTO({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'phoneNumber': phoneNumber,
  };
}

class User extends UserDTO {
  final String id;

  User({
    required this.id,
    required super.name,
    required super.email,
    required super.password,
    required super.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, ...super.toJson()};
}
