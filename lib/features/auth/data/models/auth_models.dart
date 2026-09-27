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
      email: (map['email'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
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
    final Map<String, dynamic> data = _unwrap(map, const ['data', 'user', 'result']);
    final Map<String, dynamic> userData = _unwrap(data, const ['user', 'profile']);

    final token = map['token'] ??
        map['access_token'] ??
        data['token'] ??
        data['access_token'] ??
        '';

    final userId = userData['id'] ??
        userData['userId'] ??
        userData['user_id'] ??
        data['id'] ??
        data['userId'] ??
        data['user_id'] ??
        map['id'] ??
        '';

    final name = userData['name'] ??
        userData['full_name'] ??
        data['name'] ??
        map['name'] ??
        '';

    final email = userData['email'] ??
        data['email'] ??
        map['email'] ??
        '';

    return LoginResponse(
      token: token.toString(),
      userId: userId.toString(),
      name: name.toString(),
      email: email.toString(),
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
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
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
    final Map<String, dynamic> data = _unwrap(map, const ['data', 'user', 'result']);
    final Map<String, dynamic> userData = _unwrap(data, const ['user', 'profile']);

    final token = map['token'] ??
        map['access_token'] ??
        data['token'] ??
        data['access_token'] ??
        '';

    final userId = userData['id'] ??
        userData['userId'] ??
        userData['user_id'] ??
        data['id'] ??
        data['userId'] ??
        data['user_id'] ??
        map['id'] ??
        '';

    final name = userData['name'] ??
        userData['full_name'] ??
        data['name'] ??
        map['name'] ??
        '';

    final email = userData['email'] ??
        data['email'] ??
        map['email'] ??
        '';

    return RegisterResponse(
      token: token.toString(),
      userId: userId.toString(),
      name: name.toString(),
      email: email.toString(),
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
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return map;
}