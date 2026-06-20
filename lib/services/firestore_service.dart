import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../models/user_profile.dart';

abstract class FirestoreService {
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> saveUserProfile(UserProfile profile);
  Stream<List<Article>> getFavorites(String uid);
  Future<void> addFavorite(String uid, Article article);
  Future<void> removeFavorite(String uid, int articleId);
  Stream<bool> isFavorite(String uid, int articleId);
}

class FirebaseFirestoreService implements FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(profile.toJson());
  }

  @override
  Stream<List<Article>> getFavorites(String uid) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Article(
          id: data['id'] as int? ?? 0,
          title: data['title'] as String? ?? '',
          url: data['url'] as String? ?? '',
          imageUrl: data['image_url'] as String? ?? '',
          newsSite: data['news_site'] as String? ?? '',
          summary: data['summary'] as String? ?? '',
          publishedAt: DateTime.parse(data['published_at'] as String? ?? DateTime.now().toIso8601String()),
        );
      }).toList();
    });
  }

  @override
  Future<void> addFavorite(String uid, Article article) async {
    final docId = '${uid}_${article.id}';
    final favData = article.toJson();
    favData['userId'] = uid;
    await _db.collection('favorites').doc(docId).set(favData);
  }

  @override
  Future<void> removeFavorite(String uid, int articleId) async {
    final docId = '${uid}_$articleId';
    await _db.collection('favorites').doc(docId).delete();
  }

  @override
  Stream<bool> isFavorite(String uid, int articleId) {
    final docId = '${uid}_$articleId';
    return _db.collection('favorites').doc(docId).snapshots().map((doc) => doc.exists);
  }
}

class MockFirestoreService implements FirestoreService {
  final SharedPreferences _prefs;
  final Map<String, StreamController<List<Article>>> _favoritesControllers = {};
  final Map<String, StreamController<bool>> _isFavoriteControllers = {};

  MockFirestoreService(this._prefs);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final profileJson = _prefs.getString('user_profile_$uid');
    if (profileJson != null) {
      return UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString('user_profile_${profile.uid}', jsonEncode(profile.toJson()));
  }

  List<Article> _getFavoritesList(String uid) {
    final favoritesJson = _prefs.getString('mock_favorites_$uid') ?? '[]';
    final List<dynamic> list = jsonDecode(favoritesJson) as List<dynamic>;
    return list.map((item) => Article.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _saveFavoritesList(String uid, List<Article> list) async {
    final listJson = jsonEncode(list.map((a) => a.toJson()).toList());
    await _prefs.setString('mock_favorites_$uid', listJson);
    
    // Notify favorites list stream
    if (_favoritesControllers.containsKey(uid)) {
      _favoritesControllers[uid]!.add(list);
    }
  }

  @override
  Stream<List<Article>> getFavorites(String uid) {
    final controller = _favoritesControllers.putIfAbsent(uid, () {
      final ctrl = StreamController<List<Article>>.broadcast();
      // Add initial data
      Timer.run(() => ctrl.add(_getFavoritesList(uid)));
      return ctrl;
    });
    return controller.stream;
  }

  @override
  Future<void> addFavorite(String uid, Article article) async {
    final list = _getFavoritesList(uid);
    if (!list.any((a) => a.id == article.id)) {
      list.add(article);
      await _saveFavoritesList(uid, list);
    }
    _updateIsFavoriteController(uid, article.id, true);
  }

  @override
  Future<void> removeFavorite(String uid, int articleId) async {
    final list = _getFavoritesList(uid);
    list.removeWhere((a) => a.id == articleId);
    await _saveFavoritesList(uid, list);
    _updateIsFavoriteController(uid, articleId, false);
  }

  void _updateIsFavoriteController(String uid, int articleId, bool isFav) {
    final key = '${uid}_$articleId';
    if (_isFavoriteControllers.containsKey(key)) {
      _isFavoriteControllers[key]!.add(isFav);
    }
  }

  @override
  Stream<bool> isFavorite(String uid, int articleId) {
    final key = '${uid}_$articleId';
    final controller = _isFavoriteControllers.putIfAbsent(key, () {
      final ctrl = StreamController<bool>.broadcast();
      Timer.run(() {
        final list = _getFavoritesList(uid);
        ctrl.add(list.any((a) => a.id == articleId));
      });
      return ctrl;
    });
    return controller.stream;
  }
}
