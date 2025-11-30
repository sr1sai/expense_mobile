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

class UsersDTO {
  final String name;
  final String email;
  final String password;
  final String phoneNumber;

  UsersDTO({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  factory UsersDTO.fromJson(Map<String, dynamic> json) {
    return UsersDTO(
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

class Users extends UsersDTO {
  final String id;

  Users({
    required this.id,
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) : super(
         name: name,
         email: email,
         password: password,
         phoneNumber: phoneNumber,
       );

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
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
