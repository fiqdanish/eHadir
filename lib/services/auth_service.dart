import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

/// Wraps FirebaseAuth + Firestore user-profile operations.
/// Exposes the current logged-in [AppUser] and auth state stream.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _loading;
  bool get isSignedIn => _currentUser != null;

  AuthService() {
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ─── Auth state listener ─────────────────────────────────
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _loading = false;
      notifyListeners();
      return;
    }
    await _loadUserProfile(firebaseUser.uid);
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('AuthService._loadUserProfile error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SIGN IN
  // ═══════════════════════════════════════════════════════════

  /// Returns null on success, or an error message string on failure.
  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadUserProfile(cred.user!.uid);
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'Ralat tidak dijangka. Sila cuba lagi.';
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  REGISTER
  // ═══════════════════════════════════════════════════════════

  /// Creates Firebase Auth user + Firestore profile.
  /// Returns null on success, or an error message string on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String program,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;
      final hash = _sha256(password);

      final user = AppUser(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        program: program,
        passwordHash: hash,
      );

      await _db.collection('users').doc(uid).set(user.toFirestore());
      _currentUser = user;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'Ralat pendaftaran. Sila cuba lagi.';
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SIGN OUT
  // ═══════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  ADMIN — MANAGE USERS
  // ═══════════════════════════════════════════════════════════

  /// Fetch all users from Firestore (admin use).
  Future<List<AppUser>> fetchAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map(AppUser.fromFirestore).toList();
  }

  /// Update a user's profile fields (name, role, program).
  Future<String?> updateUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.id).update({
        'name': user.name,
        'role': user.role.name,
        'program': user.program,
      });
      // If updating self, refresh in memory
      if (_currentUser?.id == user.id) {
        _currentUser = user;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Gagal mengemaskini profil.';
    }
  }

  /// Simulates a password reset email. In production, call
  /// FirebaseAuth.sendPasswordResetEmail(). Here we simulate
  /// by updating passwordHash and showing a snackbar message.
  Future<String?> simulatePasswordReset(AppUser user) async {
    try {
      // In real app: await _auth.sendPasswordResetEmail(email: user.email);
      final newPassword = 'Ikm@${DateTime.now().millisecondsSinceEpoch % 10000}';
      final hash = _sha256(newPassword);
      await _db.collection('users').doc(user.id).update({
        'passwordHash': hash,
      });
      return newPassword; // Return so caller can display it in snackbar
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Returns first 16 chars of sha256 hex as mock hash for display.
  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return '${digest.toString().substring(0, 16)}...';
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tiada akaun dengan e-mel ini.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mel atau kata laluan tidak sah.';
      case 'email-already-in-use':
        return 'E-mel ini telah didaftarkan.';
      case 'invalid-email':
        return 'Format e-mel tidak sah.';
      case 'weak-password':
        return 'Kata laluan terlalu lemah (sekurang-kurangnya 6 aksara).';
      case 'too-many-requests':
        return 'Terlalu banyak percubaan. Sila cuba lagi selepas beberapa minit.';
      case 'network-request-failed':
        return 'Tiada sambungan internet. Sila semak rangkaian anda.';
      default:
        return 'Ralat: $code';
    }
  }
}

final authProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});
