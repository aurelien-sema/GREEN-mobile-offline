import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    passwordHash: json['password_hash'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'password_hash': passwordHash,
  };
}

class AuthService {
  static const _fileName = 'users.json';
  List<UserModel> _users = [];
  static const _pbkdf2Iterations = 10000;
  static const _saltLength = 16;

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    if (_users.isNotEmpty) return;
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _users = [];
        return;
      }
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _users = list.map((e) => UserModel.fromJson(e)).toList();
    } catch (_) {
      _users = [];
    }
  }

  Future<void> _save() async {
    final file = await _getFile();
    await file.writeAsString(
      jsonEncode(_users.map((e) => e.toJson()).toList()),
    );
  }

  // Register with plaintext password; stores PBKDF2 hashed password with salt.
  Future<bool> registerWithPassword(UserModel user, String password) async {
    await _load();
    // Prevent registering with an email or phone that already exists (if provided)
    final emailLower = user.email.trim().toLowerCase();
    final phoneTrim = user.phone.trim();
    if (emailLower.isNotEmpty &&
        _users.any((u) => u.email.toLowerCase() == emailLower)) {
      return false;
    }
    if (phoneTrim.isNotEmpty &&
        _users.any((u) => u.phone.trim() == phoneTrim)) {
      return false;
    }
    final hashed = _hashPassword(password);
    final stored = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      passwordHash: hashed,
    );
    _users.add(stored);
    await _save();
    return true;
  }

  /// Get a user by identifier: if identifier contains '@' search email, otherwise phone.
  UserModel? getUserByIdentifier(String identifier) {
    final id = identifier.trim();
    if (id.contains('@')) {
      try {
        return _users.firstWhere(
          (u) => u.email.toLowerCase() == id.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
    try {
      return _users.firstWhere((u) => u.phone.trim() == id);
    } catch (_) {
      return null;
    }
  }

  /// Login with either email or phone identifier.
  Future<UserModel?> loginWithIdentifierAndPassword(
    String identifier,
    String password,
  ) async {
    await _load();
    try {
      final user = getUserByIdentifier(identifier);
      if (user != null && _verifyPassword(password, user.passwordHash)) {
        return user;
      }
    } catch (_) {}
    return null;
  }

  // Login using plaintext password; verifies against stored PBKDF2 hash.
  Future<UserModel?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _load();
    try {
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (_verifyPassword(password, user.passwordHash)) return user;
    } catch (_) {}
    return null;
  }

  // PBKDF2 implementation (HMAC-SHA256)
  String _hashPassword(String password) {
    final salt = _generateSalt(_saltLength);
    final dk = _pbkdf2(utf8.encode(password), salt, _pbkdf2Iterations, 32);
    final saltB64 = base64Encode(salt);
    final dkB64 = base64Encode(dk);
    return 'pbkdf2_sha256\$$_pbkdf2Iterations\$$saltB64\$$dkB64';
  }

  bool _verifyPassword(String password, String stored) {
    try {
      final parts = stored.split('\$');
      if (parts.length != 4) return false;
      final iterations = int.parse(parts[1]);
      final salt = base64Decode(parts[2]);
      final derived = base64Decode(parts[3]);
      final dk = _pbkdf2(
        utf8.encode(password),
        salt,
        iterations,
        derived.length,
      );
      return _constantTimeEquals(dk, derived);
    } catch (_) {
      return false;
    }
  }

  List<int> _generateSalt(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int dkLen,
  ) {
    final hLen = 32; // SHA-256 output
    final blocks = (dkLen + hLen - 1) ~/ hLen;
    final out = <int>[];
    for (var i = 1; i <= blocks; i++) {
      final blockIndex = <int>[
        (i >> 24) & 0xff,
        (i >> 16) & 0xff,
        (i >> 8) & 0xff,
        i & 0xff,
      ];
      var u = Hmac(
        sha256,
        password,
      ).convert(<int>[...salt, ...blockIndex]).bytes;
      final t = List<int>.from(u);
      for (var j = 1; j < iterations; j++) {
        u = Hmac(sha256, password).convert(u).bytes;
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.addAll(t);
    }
    return Uint8List.fromList(out.sublist(0, dkLen));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Delete a user by identifier (email or phone).
  Future<bool> deleteUserByIdentifier(String identifier) async {
    await _load();
    final user = getUserByIdentifier(identifier);
    if (user == null) return false;
    _users.removeWhere((u) => u.id == user.id);
    await _save();
    return true;
  }
}

final authService = AuthService();
