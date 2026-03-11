import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'recalculate_ratings.dart';
import 'partnership_migration.dart';
import '../services/reliability_service.dart';

/// Delete meetups that have no imageUrl or empty imageUrl
Future<int> deleteMeetupsWithoutImages() async {
  final firestore = FirebaseFirestore.instance;
  final meetupsSnapshot = await firestore.collection('meetups').get();

  int deletedCount = 0;

  for (final doc in meetupsSnapshot.docs) {
    final data = doc.data();
    final imageUrl = data['imageUrl'] as String?;

    // Check if imageUrl is null, empty, or just whitespace
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      await firestore.collection('meetups').doc(doc.id).delete();
      deletedCount++;
      debugPrint('Deleted meetup without image: ${doc.id} - ${data['title']}');
    }
  }

  debugPrint('Total deleted meetups: $deletedCount');
  return deletedCount;
}

/// Recalculate totalMeetupsJoined for all users based on actual meetup participantIds
Future<Map<String, int>> recalculateMeetupCounts() async {
  final firestore = FirebaseFirestore.instance;
  final meetupsSnapshot = await firestore.collection('meetups').get();

  // Count meetups per user from participantIds arrays
  final Map<String, int> userMeetupCounts = {};

  for (final doc in meetupsSnapshot.docs) {
    final data = doc.data();
    final participantIds = (data['participantIds'] as List<dynamic>?)?.cast<String>() ?? [];

    for (final userId in participantIds) {
      userMeetupCounts[userId] = (userMeetupCounts[userId] ?? 0) + 1;
    }
  }

  // Update each user's totalMeetupsJoined
  for (final entry in userMeetupCounts.entries) {
    await firestore.collection('users').doc(entry.key).update({
      'totalMeetupsJoined': entry.value,
    });
    debugPrint('Updated user ${entry.key}: totalMeetupsJoined = ${entry.value}');
  }

  debugPrint('Recalculated meetup counts for ${userMeetupCounts.length} users');
  return userMeetupCounts;
}

/// Recalculate reliability fields for ALL users using attendance results.
/// Missing attendance result is treated as attended (benefit of doubt).
Future<Map<String, int>> recalculateAllReliabilityScores() async {
  final firestore = FirebaseFirestore.instance;
  final reliabilityService = ReliabilityService();
  final now = DateTime.now();

  final usersSnapshot = await firestore.collection('users').get();
  final meetupsSnapshot = await firestore.collection('meetups').get();

  final registeredByUser = <String, int>{};
  final attendedByUser = <String, int>{};
  int processedMeetups = 0;

  for (final meetupDoc in meetupsSnapshot.docs) {
    final data = meetupDoc.data();
    final participantIds = (data['participantIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final participants = participantIds.toSet();

    if (participants.length < 2) continue;

    DateTime? startDate;
    final dateField = data['date'];
    if (dateField is Timestamp) {
      startDate = dateField.toDate();
    } else if (dateField is String) {
      startDate = DateTime.tryParse(dateField);
    }

    DateTime? endDate;
    final endDateField = data['endDate'];
    if (endDateField is Timestamp) {
      endDate = endDateField.toDate();
    } else if (endDateField is String) {
      endDate = DateTime.tryParse(endDateField);
    }

    final effectiveDate = endDate ?? startDate;
    if (effectiveDate == null || effectiveDate.isAfter(now)) continue;

    processedMeetups++;

    for (final userId in participants) {
      registeredByUser[userId] = (registeredByUser[userId] ?? 0) + 1;
      attendedByUser[userId] = (attendedByUser[userId] ?? 0) + 1;
    }

    final noShowSnapshot = await meetupDoc.reference
        .collection('attendance_records')
        .where('status', isEqualTo: 'not_attended')
        .get();

    for (final resultDoc in noShowSnapshot.docs) {
      final userId = resultDoc.id;
      if (!participants.contains(userId)) continue;

      final current = attendedByUser[userId] ?? 0;
      attendedByUser[userId] = current > 0 ? current - 1 : 0;
    }
  }

  int updatedUsers = 0;
  int failedUsers = 0;

  WriteBatch batch = firestore.batch();
  int batchOps = 0;

  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    final registered = registeredByUser[userId] ?? 0;
    final joined = attendedByUser[userId] ?? 0;
    final score = reliabilityService.calculateReliabilityScore(joined, registered);

    batch.update(userDoc.reference, {
      'totalMeetupsRegistered': registered,
      'totalMeetupsJoined': joined,
      'reliabilityScore': score,
    });
    batchOps++;
    updatedUsers++;

    // Keep safe margin under Firestore's 500 writes per batch limit.
    if (batchOps >= 400) {
      try {
        await batch.commit();
      } catch (e) {
        debugPrint('Reliability batch commit error: $e');
        failedUsers += batchOps;
      }
      batch = firestore.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Reliability final batch commit error: $e');
      failedUsers += batchOps;
    }
  }

  final successfulUsers = (updatedUsers - failedUsers).clamp(0, updatedUsers);
  debugPrint(
    'Reliability recalculation done: '
    'users=${usersSnapshot.docs.length}, '
    'updated=$successfulUsers, '
    'failed=$failedUsers, '
    'meetups=$processedMeetups',
  );

  return {
    'usersTotal': usersSnapshot.docs.length,
    'usersUpdated': successfulUsers,
    'usersFailed': failedUsers,
    'meetupsProcessed': processedMeetups,
  };
}

/// Admin utility screen for one-time maintenance tasks
class AdminActionsScreen extends StatefulWidget {
  const AdminActionsScreen({super.key});

  @override
  State<AdminActionsScreen> createState() => _AdminActionsScreenState();
}

class _AdminActionsScreenState extends State<AdminActionsScreen> {
  bool _isRecalculating = false;
  bool _isDeleting = false;
  bool _isMigrating = false;
  bool _isRecalculatingMeetups = false;
  bool _isRecalculatingReliability = false;
  String? _resultMessage;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _runRecalculation() async {
    setState(() {
      _isRecalculating = true;
      _resultMessage = null;
    });

    try {
      await recalculateAllUserRatings();
      setState(() {
        _resultMessage = l10n.adminRatingsRecalculateSuccess;
        _isRecalculating = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isRecalculating = false;
      });
    }
  }

  Future<void> _deleteMeetupsWithoutImages() async {
    setState(() {
      _isDeleting = true;
      _resultMessage = null;
    });

    try {
      final deletedCount = await deleteMeetupsWithoutImages();
      setState(() {
        _resultMessage = 'Başarılı! $deletedCount adet görselsiz etkinlik silindi.';
        _isDeleting = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isDeleting = false;
      });
    }
  }

  Future<void> _runPartnershipMigration() async {
    setState(() {
      _isMigrating = true;
      _resultMessage = null;
    });

    try {
      await PartnershipMigration().migrate();
      setState(() {
        _resultMessage =
            l10n.adminPartnershipMigrationSuccess;
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isMigrating = false;
      });
    }
  }

  Future<void> _runMeetupRecalculation() async {
    setState(() {
      _isRecalculatingMeetups = true;
      _resultMessage = null;
    });

    try {
      final counts = await recalculateMeetupCounts();
      setState(() {
        _resultMessage =
            'Başarılı! ${counts.length} kullanıcının etkinlik sayacı güncellendi.';
        _isRecalculatingMeetups = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isRecalculatingMeetups = false;
      });
    }
  }

  Future<void> _runReliabilityRecalculation() async {
    setState(() {
      _isRecalculatingReliability = true;
      _resultMessage = null;
    });

    try {
      final result = await recalculateAllReliabilityScores();
      final updated = result['usersUpdated'] ?? 0;
      final total = result['usersTotal'] ?? 0;
      final failed = result['usersFailed'] ?? 0;

      setState(() {
        _resultMessage =
            'Başarılı! Güvenilirlik skorları güncellendi: $updated/$total'
            '${failed > 0 ? ' (hata: $failed)' : ''}.';
        _isRecalculatingReliability = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isRecalculatingReliability = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminActions),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Puan İstatistiklerini Yeniden Hesapla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu işlem tüm kullanıcıların averageRating ve totalRatings değerlerini mevcut puanlardan yeniden hesaplar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRecalculating ? null : _runRecalculation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRecalculating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.adminRecalculateButton),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Görselsiz Etkinlikleri Sil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu işlem imageUrl alanı boş veya null olan tüm etkinlikleri siler. DİKKAT: Bu işlem geri alınamaz!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isDeleting ? null : _deleteMeetupsWithoutImages,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.adminDeleteImageLessButton),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Partnership Migration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Eski takipçi/takip alanlarını temizler ve geçmişte birlikte etkinlik yapmış kullanıcıları otomatik olarak Spor Partneri yapar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isMigrating ? null : _runPartnershipMigration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF13EC5B),
                foregroundColor: Colors.white,
              ),
              child: _isMigrating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.adminPartnershipMigrationButton),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Etkinlik Sayaçlarını Yeniden Hesapla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tüm kullanıcıların totalMeetupsJoined değerini, meetup participantIds verilerinden yeniden hesaplar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRecalculatingMeetups ? null : _runMeetupRecalculation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: _isRecalculatingMeetups
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.adminMeetupRecalculateButton),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Güvenilirlik Skorlarını Güncelle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tüm kullanıcılar için totalMeetupsRegistered, totalMeetupsJoined ve reliabilityScore alanlarını attendance sonuçlarına göre yeniden hesaplar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRecalculatingReliability ? null : _runReliabilityRecalculation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: _isRecalculatingReliability
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.adminReliabilityRecalculateButton),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultMessage!.startsWith('Hata')
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _resultMessage!.startsWith('Hata')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _resultMessage!.startsWith('Hata')
                        ? Colors.red[900]
                        : Colors.green[900],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
