import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'partnership_service.dart';
import '../models/partnership_model.dart';

class MessagingPermissionService {
  final PartnershipService _partnershipService = PartnershipService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user can send direct message to another user
  Future<bool> canSendDirectMessage(String senderId, String receiverId) async {
    try {
      final partnership = await _partnershipService.getPartnershipStatus(senderId, receiverId);
      return partnership?.status == PartnershipStatus.accepted;
    } catch (e) {
      debugPrint('Error checking DM permission: $e');
      return false;
    }
  }

  /// Get messaging lock reason (returns null if messaging is allowed)
  Future<String?> getMessagingLockReason(String userId1, String userId2) async {
    final canMessage = await canSendDirectMessage(userId1, userId2);
    if (canMessage) return null;
    return 'Bu kullanıcıya mesaj atmak veya partner eklemek için, önce aynı sahada ter dökmelisiniz. Hemen bir etkinlik oluşturun veya aynı etkinliğe katılın!';
  }

  /// Check if user can access group chat (no partnership required)
  Future<bool> canAccessGroupChat(String userId, String meetupId) async {
    try {
      final meetupDoc = await _firestore.collection('meetups').doc(meetupId).get();
      if (!meetupDoc.exists) return false;
      final data = meetupDoc.data() as Map<String, dynamic>;
      final participantIds = (data['participantIds'] as List<dynamic>?)?.cast<String>() ?? [];
      return participantIds.contains(userId);
    } catch (e) {
      debugPrint('Error checking group chat access: $e');
      return false;
    }
  }
}
