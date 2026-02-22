import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public getters to access private instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Current User Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get Current User ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Error Message Mapper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi şu an devre dışı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen bir süre bekleyin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin. ($code)';
    }
  }

  // Sign In
  Future<UserModel> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Fetch user data from Firestore with timeout
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        // Recovery: Create default user model if missing in Firestore
        final recoveredUser = UserModel(
          id: result.user!.uid,
          email: email,
          username: email.split('@')[0], // Default username from email
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(recoveredUser.toJson())
            .timeout(const Duration(seconds: 10));

        return recoveredUser;
      }

      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      throw Exception('Giriş yapılırken beklenmedik bir hata oluştu: $e');
    }
  }

  // Sign Up (Full - with username)
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    UserCredential? result;
    try {
      // 1. Create Auth User
      result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('Kayıt oluşturulamadı');
      }

      // 2. Create User Model
      UserModel newUser = UserModel(
        id: result.user!.uid,
        username: username,
        email: email,
      );

      // 3. Save to Firestore with timeout
      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toJson())
          .timeout(const Duration(seconds: 10));

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      // Rollback: Delete the auth user if Firestore write fails
      if (result?.user != null) {
        try {
          await result!.user!.delete();
        } catch (_) {
          // Ignore delete error, we can't do much about it here
        }
      }
      throw Exception('Kayıt olurken veritabanı hatası: $e');
    }
  }

  // Sign Up (Email Only - Firestore profile created later)
  Future<void> signUpWithEmailOnly({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('Kayıt oluşturulamadı');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  // Create User Profile in Firestore
  Future<void> createUserProfile({
    required String username,
    String? bio,
    String? location,
    String? gender,
    DateTime? birthDate,
    int? height,
    int? weight,
    List<String>? interestedSports,
    String? profileImageUrl,
    dynamic level,
    dynamic playStyle,
  }) async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    try {
      final userData = {
        'id': authUser.uid,
        'username': username,
        'email': authUser.email ?? '',
        'bio': bio,
        'location': location,
        'gender': gender,
        'birthDate': birthDate?.toIso8601String(),
        'height': height,
        'weight': weight,
        'interestedSports': interestedSports,
        'profileImageUrl': profileImageUrl,
        'partnersCount': 0,
        'partners': [],
        'badges': [],
        'certificates': [],
        'level': level?.toString().split('.').last ?? 'beginner',
        'playStyle': playStyle?.toString().split('.').last ?? 'casual',
      };

      await _firestore
          .collection('users')
          .doc(authUser.uid)
          .set(userData)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Profil oluşturulurken hata: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    // Remove FCM token before signing out
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
        }
      }
    } catch (e) {
      // Don't block logout if token removal fails
      debugPrint('Error removing FCM token on logout: $e');
    }
    await _auth.signOut();
  }

  // Get Current User Data
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Update User Profile
  Future<void> updateUser({
    required String userId,
    String? username,
    String? bio,
    String? location,
    String? gender,
    String? profileImageUrl,
    dynamic level,
    dynamic playStyle,
    DateTime? birthDate,
    int? height,
    int? weight,
    List<String>? interestedSports,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }
      if (bio != null) {
        updateData['bio'] = bio;
      }
      if (location != null) {
        updateData['location'] = location;
      }
      if (gender != null) {
        updateData['gender'] = gender;
      }
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      if (level != null) {
        updateData['level'] = level.toString().split('.').last;
      }
      if (playStyle != null) {
        updateData['playStyle'] = playStyle.toString().split('.').last;
      }
      if (birthDate != null) {
        updateData['birthDate'] = birthDate.toIso8601String();
      }
      if (height != null) {
        updateData['height'] = height;
      }
      if (weight != null) {
        updateData['weight'] = weight;
      }
      if (interestedSports != null) {
        updateData['interestedSports'] = interestedSports;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update(updateData)
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }
}
