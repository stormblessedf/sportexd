import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'recalculate_ratings.dart';
import 'partnership_migration.dart';

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
  String? _resultMessage;

  Future<void> _runRecalculation() async {
    setState(() {
      _isRecalculating = true;
      _resultMessage = null;
    });

    try {
      await recalculateAllUserRatings();
      setState(() {
        _resultMessage = 'Başarılı! Tüm kullanıcı puanları güncellendi.';
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
            'Başarılı! Partnership migration tamamlandı. Geçmiş etkinliklerdeki kullanıcı çiftleri partner olarak eklendi.';
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Hata: $e';
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin İşlemleri'),
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
                  : const Text('Yeniden Hesapla'),
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
                  : const Text('Görselsiz Etkinlikleri Sil'),
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
                  : const Text('Partnership Migration Başlat'),
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
