import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Sign Up
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

  // Sign Out
  Future<void> signOut() async {
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

  // Follow User
  Future<void> followUser(String currentUserId, String targetUserId) async {
    // Update current user's following list
    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId])
    });

    // Update target user's followers list
    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId])
    });
  }

  // Unfollow User
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    // Update current user's following list
    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId])
    });

    // Update target user's followers list
    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  }
