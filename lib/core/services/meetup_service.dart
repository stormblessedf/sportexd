import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meetup_model.dart';

class MeetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Placeholder images for each sport category (10 images per category)
  static const Map<MeetupType, List<String>> _placeholderImages = {
    // ⚽ Futbol
    MeetupType.football: [
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1551958219-acbc608c6377?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1486286701208-1d58e9338013?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1459865264687-595d652de67e?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏀 Basketbol
    MeetupType.basketball: [
      'https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1515523110800-9415d13b84a8?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1474224017046-182ece80b263?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1519861531473-9200262188bf?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504450758481-7338eba7524a?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1574623452334-1e0ac2b3ccb4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1494199505258-5f95387f933c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518063319789-7217e6706b04?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1559692048-79a3f837883d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1627627256672-027a4613d028?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏐 Voleybol
    MeetupType.volleyball: [
      'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1547347298-4074fc3086f0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1592656094267-764a45160876?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1553005746-9245ba190489?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1594623930572-300a3011d9ae?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1588492069485-d05b56b2831d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1562552052-c8c0b0739dda?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1610019374007-3d222c26b214?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1543351611-58f69d7c1781?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
    ],
    // 🎾 Tenis
    MeetupType.tennis: [
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1529926706528-db9e5010cd3e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1544298621-35a989e88a63?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1617083934551-ac1f1c240d63?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1599586120429-48281b6f0ece?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1560012057-4372e14c5085?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1542144612-1b3641ec3459?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏓 Masa Tenisi
    MeetupType.tableTennis: [
      'https://images.unsplash.com/photo-1534158914592-062992fbe900?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1609710228159-0fa9bd7c0827?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1558743212-d5bfb8a5e3c4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1611251135345-18c56206b863?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1593766788306-28561086694e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1567289893553-cb206a65bae0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1519744434544-7efc6d1f22e3?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1606567595334-d39972c85dfd?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏸 Badminton
    MeetupType.badminton: [
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1613918431703-aa50889e3be5?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1599391398131-cd12dfc6b77c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1617883861744-13b534e3b928?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1565992441121-4367c2967103?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1629276301820-0f3eedc29fd0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1593786267440-6c71c6c2b3f0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1551632436-cbf8dd35adfa?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1616442830889-1465c9e1be15?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1553005746-9245ba190489?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏊 Yüzme
    MeetupType.swimming: [
      'https://images.unsplash.com/photo-1530549387789-4c1017266635?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1519315901367-f34ff9154487?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1560090995-01632a28895b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1600965962361-9035dbfd1c50?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1622629797619-c100e3e67e2e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1519315901367-f34ff9154487?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏃 Koşu
    MeetupType.running: [
      'https://images.unsplash.com/photo-1571008887538-b36bb32f4571?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1461896836934-aca0a5b1c94e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1483721310020-03333e577078?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1486218119243-13883505764c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1587019158091-1a103c5dd17f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1594882645126-14020914d58d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1590333748338-d629e4564ad9?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1558017487-06bf9f82613a?auto=format&fit=crop&w=800&q=80',
    ],
    // 🚴 Bisiklet
    MeetupType.cycling: [
      'https://images.unsplash.com/photo-1541625602330-2277a4c46182?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1507035895480-2b3156c31fc8?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1605711285791-0219e80e43a3?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1583467875263-d50dec37a88c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1594739393338-9e14b214e92c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1571068316344-75bc76f77890?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1534787238916-9ba6764efd4f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1576858574144-9ae1ebcf5ae5?auto=format&fit=crop&w=800&q=80',
    ],
    // 🥾 Doğa Yürüyüşü
    MeetupType.hiking: [
      'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1533240332313-0db49b459ad6?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1587502537104-aac10f5fb6f7?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1445307806294-bff7f67ff225?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1527004013197-933c4bb611b3?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1486911278844-a81c5267e227?auto=format&fit=crop&w=800&q=80',
    ],
    // 🧘 Yoga
    MeetupType.yoga: [
      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1545205597-3d9d02c29597?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1524863479829-916d8e77f114?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1510894347713-fc3ed6fdf539?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1573384666979-2b1e160d2d08?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1562088287-bde35a1ea917?auto=format&fit=crop&w=800&q=80',
    ],
    // 🏋️ Fitness
    MeetupType.fitness: [
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1576678927484-cc907957088c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1593079831268-3381b0db4a77?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=crop&w=800&q=80',
    ],
    // 🥊 Boks
    MeetupType.boxing: [
      'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517438322307-e67111335449?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1564415051543-cb73a44a157a?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1495555687398-3f50d6e79e1e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517438476312-10d79c077509?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1552072092-7f9b8d63efcb?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1544117519-31a4b719223d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1615117950234-f84e58b26039?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1590056468517-336a4986c51b?auto=format&fit=crop&w=800&q=80',
    ],
    // 🧗 Tırmanış
    MeetupType.climbing: [
      'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1516592673884-4a382d1124c3?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1564769662533-4f00a87b4056?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1601024445121-e5b82f020549?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1502126324834-38f8e02d7160?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1606859191214-25bd274fcdd5?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517859799970-5f2f5f7c2f6c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1587749091230-fb8e20393e79?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1594498257662-c3c0e9b7afbb?auto=format&fit=crop&w=800&q=80',
    ],
    // ⛷️ Kayak
    MeetupType.skiing: [
      'https://images.unsplash.com/photo-1551524559-8af4e6624178?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1565992441121-4367c2967103?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1605540436563-5bca919ae766?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1488282396544-0212eea56a21?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1610391704875-79fd49d7ea80?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1579621970795-87facc2f976d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1491002052546-bf38f186af56?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1544988809-026f2b5c5b9b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1520466809213-7b9a56adcd45?auto=format&fit=crop&w=800&q=80',
    ],
    // 🎯 Diğer
    MeetupType.other: [
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1579952363873-27f3bde9be2d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1461896836934-aca0a5b1c94e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1599058917212-d750089bc07e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1576678927484-cc907957088c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?auto=format&fit=crop&w=800&q=80',
    ],
  };

  /// Get a random placeholder image for the given meetup type
  String getRandomPlaceholderImage(MeetupType type) {
    final images =
        _placeholderImages[type] ?? _placeholderImages[MeetupType.other]!;
    return images[_random.nextInt(images.length)];
  }

  // Collection Reference
  CollectionReference get _meetupsRef => _firestore.collection('meetups');

  // Create Meetup
  Future<void> createMeetup({
    required String title,
    required String description,
    required MeetupType type,
    required DateTime date,
    DateTime? endDate,
    required String locationName,
    required String locationAddress,
    required int maxParticipants,
    required String organizerId,
    required String organizerName,
    String? organizerImageUrl,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final docRef = _meetupsRef.doc(); // Generate ID

    // Use provided imageUrl or get random placeholder based on category
    final finalImageUrl = imageUrl ?? getRandomPlaceholderImage(type);

    final meetup = MeetupModel(
      id: docRef.id,
      title: title,
      description: description,
      imageUrl: finalImageUrl,
      type: type,
      date: date,
      endDate: endDate,
      locationName: locationName,
      locationAddress: locationAddress,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerImageUrl: organizerImageUrl,
      currentParticipants: 1, // Organizer joins automatically
      maxParticipants: maxParticipants,
      participantIds: [organizerId],
      latitude: latitude,
      longitude: longitude,
    );

    await docRef.set(meetup.toJson());
  }

  // Get Meetups Stream (All meetups - deprecated, use getUpcomingMeetups instead)
  @Deprecated('Use getUpcomingMeetups() to show only upcoming events')
  Stream<List<MeetupModel>> getMeetups() {
    return _meetupsRef.orderBy('date', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Upcoming Meetups (Future events only)
  Stream<List<MeetupModel>> getUpcomingMeetups() {
    final now = DateTime.now();

    return _meetupsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // Get Past Meetups for User (Events user participated in that are now past)
  Stream<List<MeetupModel>> getPastMeetupsForUser(String userId) {
    final now = DateTime.now();

    return _meetupsRef
        .where('participantIds', arrayContains: userId)
        .where('date', isLessThan: Timestamp.fromDate(now))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // Check if meetup is in the past
  bool isMeetupPast(MeetupModel meetup) {
    return meetup.date.isBefore(DateTime.now());
  }

  // Get User Meetups (My Chats)
  Stream<List<MeetupModel>> getUserMeetups(String userId) {
    return _meetupsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // Get Single Meetup
  Future<MeetupModel?> getMeetup(String id) async {
    final doc = await _meetupsRef.doc(id).get();
    if (!doc.exists) return null;
    return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Alias for getMeetup (for consistency)
  Future<MeetupModel?> getMeetupById(String id) async {
    return getMeetup(id);
  }

  // Join Meetup (Bonus for Phase 2)
  Future<void> joinMeetup(String meetupId, String userId) async {
    // Transaction to ensure atomic update of participant count
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!snapshot.exists) throw Exception("Meetup not found");
      if (participantSnapshot.exists) return; // Already joined

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      if (meetup.currentParticipants >= meetup.maxParticipants) {
        throw Exception("Meetup is full");
      }

      // Add user to participants subcollection
      transaction.set(participantRef, {
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Increment counter and add to participantIds array
      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(1),
        'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
        'participantIds': FieldValue.arrayUnion([userId]),
        'waitlistUserIds': FieldValue.arrayRemove([
          userId,
        ]), // Remove from waitlist if present
      });
    });
  }

  // Check if user is participant
  Future<bool> isParticipant(String meetupId, String userId) async {
    final doc = await _meetupsRef
        .doc(meetupId)
        .collection('participants')
        .doc(userId)
        .get();
    return doc.exists;
  }

  // Join Waitlist - Add user to waitlist when event is full
  Future<void> joinWaitlist(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Meetup not found");

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Don't allow joining waitlist if user is already a participant
      if (meetup.participantIds.contains(userId)) {
        throw Exception("You are already a participant");
      }

      // Don't allow joining waitlist if already on it
      if (meetup.waitlistUserIds.contains(userId)) {
        return; // Already on waitlist
      }

      // Add user to waitlist
      transaction.update(docRef, {
        'waitlistUserIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  // Leave Waitlist - Remove user from waitlist
  Future<void> leaveWaitlist(String meetupId, String userId) async {
    await _meetupsRef.doc(meetupId).update({
      'waitlistUserIds': FieldValue.arrayRemove([userId]),
    });
  }

  // Check if user is on waitlist
  Future<bool> isOnWaitlist(String meetupId, String userId) async {
    final doc = await _meetupsRef.doc(meetupId).get();
    if (!doc.exists) return false;

    final meetup = MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
    return meetup.waitlistUserIds.contains(userId);
  }

  // Leave Meetup - Remove user from meetup participants
  Future<void> leaveMeetup(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Meetup not found");

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Organizer cannot leave their own meetup
      if (meetup.organizerId == userId) {
        throw Exception("Organizatör kendi etkinliğinden ayrılamaz");
      }

      // Check if user is actually a participant
      if (!meetup.participantIds.contains(userId)) {
        throw Exception("Bu etkinliğe katılmadınız");
      }

      // Remove user from participants subcollection
      transaction.delete(participantRef);

      // Decrement counter and remove from participantIds array
      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(-1),
        'isFull': false, // No longer full since someone left
        'participantIds': FieldValue.arrayRemove([userId]),
      });
    });
  }
}
