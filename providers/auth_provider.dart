import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel?  get user   => _user;
  String?     get error  => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _auth.authStateChanges().listen((fu) async {
      if (fu == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        await _load(fu.uid);
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  Future<void> _load(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) _user = UserModel.fromMap(doc.data()!);
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading; _error = null; notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _msg(e.code); _status = AuthStatus.error; notifyListeners();
      return false;
    }
  }

  Future<bool> register({required String name, required String email,
    required String password, required String phone}) async {
    _status = AuthStatus.loading; _error = null; notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final u = UserModel(uid: cred.user!.uid, name: name, email: email,
          phone: phone, createdAt: DateTime.now());
      await _db.collection('users').doc(cred.user!.uid).set(u.toMap());
      await cred.user!.updateDisplayName(name);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _msg(e.code); _status = AuthStatus.error; notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null; _status = AuthStatus.unauthenticated; notifyListeners();
  }

  String _msg(String code) {
    switch (code) {
      case 'user-not-found':   return 'No account found with this email.';
      case 'wrong-password':   return 'Incorrect password.';
      case 'email-already-in-use': return 'Account already exists.';
      case 'weak-password':    return 'Password too short (min 6 chars).';
      case 'invalid-email':    return 'Invalid email address.';
      default: return 'Authentication failed. Try again.';
    }
  }
}