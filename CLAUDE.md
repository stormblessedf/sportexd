# Sporsal - Claude Code Proje Kuralları

## Proje Hakkında
Sporsal, spor tutkunlarının buluşma organize etmesini ve spor arkadaşı bulmasını sağlayan bir Flutter uygulamasıdır.

## Teknoloji Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Routing:** GoRouter
- **UI:** Material Design 3, Google Fonts (Outfit)

## Klasör Yapısı
```
lib/
├── core/
│   ├── models/      # UserModel, MeetupModel, MessageModel
│   └── services/    # AuthService, MeetupService, ChatService
├── features/
│   ├── auth/        # Login, Signup
│   ├── home/        # Ana sayfa
│   ├── meetups/     # Buluşma oluşturma/detay
│   ├── chat/        # Mesajlaşma
│   └── profile/     # Profil
└── theme/           # AppTheme
```

## Kodlama Kuralları

### Dil
- Tüm kullanıcı arayüzü metinleri **Türkçe** olmalı
- Hata mesajları Türkçe ve kullanıcı dostu olmalı
- Kod ve yorum İngilizce olabilir

### Flutter Best Practices
- `context.mounted` kontrolü async işlemlerden sonra
- `const` constructor kullanımı
- Provider ile servis erişimi: `context.read<Service>()`

### Firestore Yapısı
- `users/` - Kullanıcı profilleri
- `meetups/` - Buluşmalar
- `chats/{meetupId}/messages/` - Chat mesajları (subcollection)

## Skill'ler
`.claude/skills/` klasöründe proje için özel skill'ler var:
- `flutter-dev` - Flutter geliştirme best practices
- `firebase-flutter` - Firebase entegrasyon kalıpları
- `sporsal` - Proje-spesifik konvansiyonlar

## Önemli Dosyalar
- `lib/main.dart` - Uygulama giriş noktası, routing, providers
- `lib/core/services/auth_service.dart` - Authentication işlemleri
- `lib/core/services/meetup_service.dart` - Buluşma CRUD işlemleri
- `lib/theme/app_theme.dart` - Tema tanımları
