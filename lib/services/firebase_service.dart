import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  String? _currentUserId;
  String? _userName;
  bool _isInitialized = false;
  String? _error;

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  String? get currentUserId => _currentUserId;
  String? get userName => _userName;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isSignedIn => auth.currentUser != null;

  Future<bool> initialize() async {
    try {
      debugPrint('🔥 Initializing Firebase service...');

      if (isSignedIn) {
        // User already exists
        _currentUserId = auth.currentUser!.uid;
        await _loadUserData();
        debugPrint('✅ Existing user loaded: $_currentUserId');
      } else {
        // Create new anonymous user
        await _createAnonymousUser();
      }

      _isInitialized = true;
      _error = null;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      _error = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _createAnonymousUser() async {
    try {
      debugPrint('🔐 Creating anonymous user...');

      final userCredential = await auth.signInAnonymously();
      _currentUserId = userCredential.user?.uid;

      if (_currentUserId != null) {
        await firestore.collection('users').doc(_currentUserId).set({
          'name': 'Anonymous',
        });

        _userName = 'Anonymous';
        debugPrint('✅ Anonymous user created: $_currentUserId');
      }
    } catch (e) {
      debugPrint('❌ Error creating anonymous user: $e');
      rethrow;
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (_currentUserId != null) {
        final userDoc = await firestore.collection('users').doc(_currentUserId).get();

        if (userDoc.exists) {
          _userName = userDoc.data()?['name'] ?? 'Anonymous';
        } else {
          await firestore.collection('users').doc(_currentUserId).set({
            'name': 'Anonymous',
          });
          _userName = 'Anonymous';
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      _userName = 'Anonymous';
    }
  }

  Future<bool> updateUserName(String newName) async {
    try {
      if (_currentUserId == null) return false;

      await firestore.collection('users').doc(_currentUserId).update({
        'name': newName,
      });

      _userName = newName;
      notifyListeners();
      debugPrint('✅ User name updated to: $newName');
      return true;

    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset service
  void reset() {
    _currentUserId = null;
    _userName = null;
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }
}