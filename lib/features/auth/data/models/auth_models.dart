class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "password": password,
    };
  }

  factory LoginRequest.fromMap(Map<String, dynamic> map) {
    return LoginRequest(
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

class LoginResponse {
  final String token;
  final String userId;
  final String name;
  final String email;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      "token": token,
      "userId": userId,
      "name": name,
      "email": email,
    };
  }

  factory LoginResponse.fromMap(Map<String, dynamic> map) {
    final data = _unwrap(map, const ['user']);

    return LoginResponse(
      token: (map['token'] ?? map['access_token'] ?? '').toString(),
      userId: (data['id'] ?? data['userId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }
}
class RegisterRequest {
  final String name;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email,
      "password": password,
    };
  }

  factory RegisterRequest.fromMap(Map<String, dynamic> map) {
    return RegisterRequest(
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

class RegisterResponse {
  final String token;
  final String userId;
  final String name;
  final String email;

  RegisterResponse({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      "token": token,
      "userId": userId,
      "name": name,
      "email": email,
    };
  }

  factory RegisterResponse.fromMap(Map<String, dynamic> map) {
    final data = _unwrap(map, const ['user']);
    return RegisterResponse(
      token: (map['token'] ?? map['access_token'] ?? '') as String,
      userId: (data['id'] ?? data['userId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
    );
  }
}

Map<String, dynamic> _unwrap(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return map;
}