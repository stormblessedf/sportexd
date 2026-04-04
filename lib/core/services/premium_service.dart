import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum PremiumPlan { monthly, annual }

class PremiumService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool _isPremium = false;
  DateTime? _premiumUntil;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? _authSubscription;

  PremiumService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  bool get isPremium => _isPremium;
  DateTime? get premiumUntil => _premiumUntil;

  bool get hasActivePremium {
    if (!_isPremium) return false;
    if (_premiumUntil == null) return true;
    return _premiumUntil!.isAfter(DateTime.now());
  }

  String? get currentUserId => _auth.currentUser?.uid;

  void initialize() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startListening(user.uid);
      } else {
        _stopListening();
        _isPremium = false;
        _premiumUntil = null;
        notifyListeners();
      }
    });
  }

  void _startListening(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data() ?? {};
        _isPremium = data['isPremium'] == true;
        final ts = data['premiumUntil'];
        _premiumUntil = ts is Timestamp ? ts.toDate() : null;
        notifyListeners();
      }
    });
  }

  void _stopListening() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  /// Returns price and duration for each plan.
  static Map<String, dynamic> planDetails(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return {
          'label': 'Aylık',
          'price': '₺79',
          'priceRaw': 79,
          'durationDays': 30,
          'savingsLabel': null,
        };
      case PremiumPlan.annual:
        return {
          'label': 'Yıllık',
          'price': '₺599',
          'priceRaw': 599,
          'durationDays': 365,
          'savingsLabel': '%37 Tasarruf',
        };
    }
  }

  /// Activates premium for the given user and duration.
  /// In production, call this ONLY after successful payment verification.
  Future<void> activatePremium({
    required String userId,
    required PremiumPlan plan,
  }) async {
    final details = planDetails(plan);
    final durationDays = details['durationDays'] as int;

    // If already premium, extend from current expiry, else from now
    DateTime base = DateTime.now();
    if (hasActivePremium && _premiumUntil != null) {
      base = _premiumUntil!;
    }
    final until = base.add(Duration(days: durationDays));

    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumUntil': Timestamp.fromDate(until),
    });
  }

  /// Cancels premium (disables auto-renew). Access continues until premiumUntil.
  Future<void> cancelPremium(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isPremium': false,
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
