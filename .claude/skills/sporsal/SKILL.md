---
name: sporsal
description: Sporsal spor buluşma uygulaması için proje-spesifik kurallar ve konvansiyonlar. Bu skill'i Sporsal projesinde çalışırken kullan - mimari, dosya yapısı, model ve servis kalıpları için.
---

# Sporsal Proje Skill'i

## Proje Genel Bakış

Sporsal, spor tutkunlarının buluşma organize etmesini ve spor arkadaşı bulmasını sağlayan bir Flutter uygulamasıdır.

**Tagline:** "Spor Arkadaşını Bul"

## Mimari

### Klasör Yapısı
```
lib/
├── core/
│   ├── models/          # Veri modelleri
│   └── services/        # İş mantığı servisleri
├── features/
│   └── [feature]/
│       └── presentation/
│           ├── [feature]_screen.dart
│           └── widgets/
├── theme/
│   └── app_theme.dart
└── main.dart
```

### Feature Modülleri
- `auth/` - Giriş, kayıt ekranları
- `home/` - Ana sayfa, buluşma listesi
- `meetups/` - Buluşma oluşturma, detay
- `chat/` - Mesajlaşma
- `profile/` - Profil görüntüleme, düzenleme

## Veri Modelleri

### UserModel
```dart
// Lokasyon: lib/core/models/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final List<Certificate> certificates;
  final List<Badge> badges;
  final int followersCount;
  final int followingCount;
  final String? location;
  final String? gender;
  final DateTime? birthDate;
  final Level level;              // beginner, intermediate, advanced
  final PreferredTime preferredTime;
  final PlayStyle playStyle;      // competitive, casual
  final List<String> followers;
  final List<String> following;
}
```

### MeetupModel
```dart
// Lokasyon: lib/core/models/meetup_model.dart
class MeetupModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final MeetupType type;          // football, yoga, tennis, basketball, running, other
  final DateTime date;
  final String locationName;
  final String locationAddress;
  final String organizerId;
  final String organizerName;
  final String? organizerImageUrl;
  final int currentParticipants;
  final int maxParticipants;
  final bool isFull;
  final List<String> participantIds;
}
```

### MessageModel
```dart
// Lokasyon: lib/core/models/message_model.dart
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String? text;
  final String? imageUrl;
  final MessageType type;         // text, image, system
  final DateTime timestamp;
}
```

## Servisler

### AuthService
```dart
// Lokasyon: lib/core/services/auth_service.dart
// Provider ile kullanım: context.read<AuthService>()

// Metodlar:
- signUp(email, password, username)
- signIn(email, password)
- signOut()
- getCurrentUser() -> Future<UserModel?>
- followUser(targetUserId)
- unfollowUser(targetUserId)
- updateUserProfile(UserModel)
```

### MeetupService
```dart
// Lokasyon: lib/core/services/meetup_service.dart

// Metodlar:
- createMeetup(MeetupModel)
- getMeetupsStream() -> Stream<List<MeetupModel>>
- getUserMeetups(userId) -> Stream<List<MeetupModel>>
- getMeetup(meetupId) -> Future<MeetupModel?>
- joinMeetup(meetupId) -> Transaction ile atomik
- isParticipant(meetupId) -> Future<bool>
```

### ChatService
```dart
// Lokasyon: lib/core/services/chat_service.dart

// Metodlar:
- sendMessage(chatId, MessageModel)
- getMessagesStream(chatId) -> Stream<List<MessageModel>>

// Firestore yapısı: chats/{meetupId}/messages/{messageId}
```

## Routing (GoRouter)

### Route Tanımları
```dart
// main.dart içinde

'/login'        -> LoginScreen
'/signup'       -> SignupScreen
'/home'         -> HomeScreen (MainShell içinde)
'/chats'        -> MyChatsScreen (MainShell içinde)
'/create'       -> CreateMeetupScreen (MainShell içinde)
'/profile'      -> ProfileScreen (MainShell içinde)
'/detail'       -> MeetupDetailScreen (extra: MeetupModel)
'/chat'         -> ChatScreen (queryParams: chatId, title)
'/edit-profile' -> EditProfileScreen (extra: UserModel)
'/create-profile' -> CreateProfileScreen
```

### Navigasyon Örnekleri
```dart
// Named route
context.goNamed('home');

// Extra data ile
context.go('/detail', extra: meetup);

// Query params ile
context.go('/chat?chatId=${meetup.id}&title=${meetup.title}');

// Geri
context.pop();
```

## Tema

### Renkler
```dart
// Primary: #6C63FF (Mor)
// Dark background: #1A1A2E (Koyu lacivert)

// Kullanım:
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
```

### Font
```dart
// Google Fonts: Outfit
GoogleFonts.outfit()
```

### Varsayılan Tema
Uygulama varsayılan olarak **dark mode** kullanır.

## Firestore Koleksiyonları

```
users/
  {userId}/
    - username, email, profileImageUrl, bio
    - certificates[], badges[]
    - followersCount, followingCount
    - location, gender, birthDate
    - level, preferredTime, playStyle
    - followers[], following[]

meetups/
  {meetupId}/
    - title, description, imageUrl
    - type, date
    - locationName, locationAddress
    - organizerId, organizerName, organizerImageUrl
    - currentParticipants, maxParticipants, isFull
    - participantIds[]

chats/
  {meetupId}/
    - lastMessage, lastMessageTime, lastSenderName
    messages/
      {messageId}/
        - senderId, senderName, senderImageUrl
        - text, imageUrl, type, timestamp
```

## Kod Stilleri

### Türkçe Kullanıcı Mesajları
```dart
// Hata mesajları Türkçe olmalı
throw 'Bu e-posta zaten kullanımda';
throw 'Şifre en az 6 karakter olmalı';

// SnackBar mesajları
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Buluşmaya katıldınız!')),
);
```

### Async İşlemler Sonrası Context Kontrolü
```dart
await someAsyncOperation();
if (!context.mounted) return;
// context kullanımı
```

### Loading State Pattern
```dart
bool _isLoading = false;

Future<void> _submit() async {
  setState(() => _isLoading = true);
  try {
    await operation();
  } catch (e) {
    // handle error
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// Button'da:
ElevatedButton(
  onPressed: _isLoading ? null : _submit,
  child: _isLoading
      ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text('Gönder'),
)
```

## Yeni Özellik Ekleme Rehberi

1. **Model gerekiyorsa:** `lib/core/models/` altına ekle
2. **Servis gerekiyorsa:** `lib/core/services/` altına ekle, `main.dart`'ta Provider'a kaydet
3. **Ekran:** `lib/features/[feature]/presentation/` altına ekle
4. **Route:** `main.dart`'ta GoRouter'a ekle
5. **Widget:** Tekrar kullanılacaksa `widgets/` alt klasörüne

## Önemli Notlar

- Buluşmaya katılım `MeetupService.joinMeetup()` ile transaction kullanır
- Chat mesajları subcollection'da saklanır
- Profil resimleri Firebase Storage'da `profile_images/` altında
- Uygulama dili Türkçe, tüm UI metinleri Türkçe olmalı
