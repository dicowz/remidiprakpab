import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

abstract class AuthService {
  UserProfile? get currentUser;
  Stream<UserProfile?> get onAuthStateChanged;
  bool get isFirebaseMode;

  Future<UserProfile> signUp(String name, String email, String password, String instagram);
  Future<UserProfile> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _cachedUser;

  @override
  bool get isFirebaseMode => true;

  @override
  UserProfile? get currentUser => _cachedUser;

  @override
  Stream<UserProfile?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cachedUser = null;
        return null;
      }
      
      // Attempt to load full user details (e.g. name, instagram) from local storage
      // or Firestore. If Firebase is active, the caller will register it.
      // For basic auth, we create a placeholder UserProfile.
      _cachedUser = UserProfile(
        uid: user.uid,
        fullName: user.displayName ?? 'Space Traveler',
        email: user.email ?? '',
        instagram: '', // Loaded from firestore in views
        profilePicUrl: 'assets/profil.png',
      );
      return _cachedUser;
    });
  }

  @override
  Future<UserProfile> signUp(String name, String email, String password, String instagram) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) throw Exception('Registration failed: User is null');

      await user.updateDisplayName(name);
      
      _cachedUser = UserProfile(
        uid: user.uid,
        fullName: name,
        email: email,
        instagram: instagram,
        profilePicUrl: 'assets/profil.png',
      );

      return _cachedUser!;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) throw Exception('Login failed: User is null');

      _cachedUser = UserProfile(
        uid: user.uid,
        fullName: user.displayName ?? 'Space Traveler',
        email: email,
        instagram: '',
        profilePicUrl: 'assets/profil.png',
      );
      return _cachedUser!;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _cachedUser = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

class MockAuthService implements AuthService {
  final SharedPreferences _prefs;
  final StreamController<UserProfile?> _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  MockAuthService(this._prefs) {
    _loadSession();
  }

  @override
  bool get isFirebaseMode => false;

  void _loadSession() {
    final activeUid = _prefs.getString('active_user_uid');
    if (activeUid != null) {
      final userJson = _prefs.getString('user_profile_$activeUid');
      if (userJson != null) {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _authController.add(_currentUser);
        return;
      }
    }
    _currentUser = null;
    _authController.add(null);
  }

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> get onAuthStateChanged => _authController.stream;

  @override
  Future<UserProfile> signUp(String name, String email, String password, String instagram) async {
    // Check if user already exists in mock database
    final existingUsersJson = _prefs.getString('mock_users') ?? '[]';
    final List<dynamic> users = jsonDecode(existingUsersJson) as List<dynamic>;
    
    for (var u in users) {
      if (u['email'] == email) {
        throw Exception('Email already registered.');
      }
    }

    final uid = 'mock_uid_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = UserProfile(
      uid: uid,
      fullName: name,
      email: email,
      instagram: instagram,
      profilePicUrl: 'assets/profil.png',
    );

    // Save profile
    await _prefs.setString('user_profile_$uid', jsonEncode(newProfile.toJson()));
    
    // Save user password mapping for authentication mock
    users.add({
      'uid': uid,
      'email': email,
      'password': password,
    });
    await _prefs.setString('mock_users', jsonEncode(users));

    // Auto login
    _currentUser = newProfile;
    await _prefs.setString('active_user_uid', uid);
    _authController.add(_currentUser);

    return newProfile;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final existingUsersJson = _prefs.getString('mock_users') ?? '[]';
    final List<dynamic> users = jsonDecode(existingUsersJson) as List<dynamic>;

    for (var u in users) {
      if (u['email'] == email && u['password'] == password) {
        final uid = u['uid'] as String;
        final profileJson = _prefs.getString('user_profile_$uid');
        if (profileJson != null) {
          final profile = UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);
          _currentUser = profile;
          await _prefs.setString('active_user_uid', uid);
          _authController.add(_currentUser);
          return profile;
        }
      }
    }
    throw Exception('Incorrect email or password.');
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove('active_user_uid');
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    // Mock password reset
    final existingUsersJson = _prefs.getString('mock_users') ?? '[]';
    final List<dynamic> users = jsonDecode(existingUsersJson) as List<dynamic>;
    bool found = false;
    for (var u in users) {
      if (u['email'] == email) {
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception('Email address not found.');
    }
    // Simulation succeeded
  }
}
