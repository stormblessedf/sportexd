# Sporsal - Uygulama Mimarisi ve Detaylı Özet

## 📱 Genel Bakış

**Sporsal**, spor yapmak isteyen kişilerin birbirlerini bulup etkinlik organize edebilecekleri sosyal bir mobil uygulamadır. Flutter ile geliştirilmiş, Firebase backend altyapısını kullanan, gerçek zamanlı özellikler içeren bir platformdur.

## 🎯 Ana Özellikler

### 1. **Etkinlik Yönetimi**
- Spor etkinliği oluşturma (futbol, basketbol, tenis, yoga vb.)
- Etkinliklere katılma/ayrılma
- Bekleme listesi sistemi (kontenjan dolduğunda)
- Harita üzerinde etkinlik görüntüleme
- Geçmiş etkinlikleri görüntüleme

### 2. **Keşfet & Filtreleme**
- Akıllı öneri sistemi (senin için, trend, yakında başlıyor, yeni etkinlikler)
- Gelişmiş filtreleme (spor türü, tarih, konum, mesafe)
- Harita ve liste görünümü
- Gerçek zamanlı arama

### 3. **Sohbet Sistemi**
- Etkinlik bazlı grup sohbetleri
- Gerçek zamanlı mesajlaşma
- Okunmamış mesaj sayacı
- Organizatör özel modu (sadece organizatör mesaj atabilir)
- Aktif ve geçmiş sohbetler

### 4. **Kullanıcı Profilleri**
- Profil fotoğrafı yükleme
- Detaylı kullanıcı bilgileri (boy, kilo, seviye, oyun stili)
- İlgi alanı sporlar
- Rozetler ve sertifikalar
- Takip/takipçi sistemi

### 5. **Değerlendirme Sistemi**
- Kullanıcı puanlama (1-5 yıldız)
- Yorum yazma
- Güvenilirlik skoru
- Puanlama dağılımı grafikleri
- Etkinlik sonrası katılımcı değerlendirme

### 6. **Bildirim Sistemi**
- Gerçek zamanlı bildirimler
- Bildirim tercihleri (etkinlik, sohbet, takip, değerlendirme)
- Firebase Cloud Messaging entegrasyonu

### 7. **Konum Servisleri**
- Google Maps entegrasyonu
- Google Places API (otomatik tamamlama)
- Mesafe hesaplama
- Haritada konum seçme
- "Haritada Aç" özelliği

## 🏗️ Teknik Mimari

### **Frontend: Flutter**

#### **Klasör Yapısı**
```
lib/
├── core/                          # Çekirdek katman
│   ├── controllers/               # İş mantığı kontrolörleri
│   │   └── discovery_controller.dart
│   ├── models/                    # Veri modelleri
│   │   ├── user_model.dart
│   │   ├── meetup_model.dart
│   │   ├── message_model.dart
│   │   ├── notification_model.dart
│   │   ├── rating_model.dart
│   │   └── ...
│   ├── services/                  # Backend servisleri
│   │   ├── auth_service.dart
│   │   ├── meetup_service.dart
│   │   ├── chat_service.dart
│   │   ├── notification_service.dart
│   │   ├── rating_service.dart
│   │   ├── places_service.dart
│   │   ├── location_service.dart
│   │   └── ...
│   ├── utils/                     # Yardımcı fonksiyonlar
│   │   ├── time_formatter.dart
│   │   ├── custom_marker_generator.dart
│   │   ├── rating_validation.dart
│   │   └── ...
│   └── widgets/                   # Paylaşılan widget'lar
│       └── user_rating_badge.dart
├── features/                      # Özellik modülleri
│   ├── auth/                      # Kimlik doğrulama
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── signup_screen.dart
│   ├── discovery/                 # Keşfet sayfası
│   │   └── presentation/
│   │       ├── discovery_page.dart
│   │       └── widgets/
│   ├── home/                      # Ana sayfa
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       └── widgets/
│   ├── meetups/                   # Etkinlik yönetimi
│   │   └── presentation/
│   │       ├── create_meetup_screen.dart
│   │       ├── meetup_detail_screen.dart
│   │       ├── nearby_meetups_map_screen.dart
│   │       ├── past_meetups_screen.dart
│   │       └── widgets/
│   ├── chat/                      # Sohbet sistemi
│   │   └── presentation/
│   │       ├── my_chats_screen.dart
│   │       ├── chat_screen.dart
│   │       └── widgets/
│   ├── profile/                   # Profil yönetimi
│   │   └── presentation/
│   │       ├── profile_screen.dart
│   │       ├── rate_user_screen.dart
│   │       ├── user_ratings_page.dart
│   │       └── widgets/
│   └── notifications/             # Bildirimler
│       └── presentation/
│           ├── notifications_screen.dart
│           └── widgets/
├── theme/                         # Tema ve renkler
│   ├── app_theme.dart
│   └── app_colors.dart
├── firebase_options.dart          # Firebase yapılandırması
└── main.dart                      # Uygulama giriş noktası
```

### **State Management**
- **Provider Pattern**: Uygulama genelinde state yönetimi
- **ChangeNotifier**: Reaktif state güncellemeleri
- **StreamBuilder**: Gerçek zamanlı veri akışları

### **Navigation**
- **GoRouter**: Deklaratif routing
- **ShellRoute**: Alt navigasyon (bottom navigation bar)
- **Named Routes**: Tip güvenli navigasyon

### **Backend: Firebase**

#### **Firebase Servisleri**
1. **Firebase Authentication**
   - Email/şifre ile kimlik doğrulama
   - Kullanıcı oturum yönetimi

2. **Cloud Firestore**
   - NoSQL veritabanı
   - Gerçek zamanlı senkronizasyon
   - Koleksiyonlar:
     - `users` - Kullanıcı profilleri
     - `meetups` - Etkinlikler
     - `chats` - Sohbet odaları
     - `messages` - Mesajlar
     - `notifications` - Bildirimler
     - `ratings` - Kullanıcı değerlendirmeleri

3. **Firebase Storage**
   - Profil fotoğrafları
   - Etkinlik görselleri

4. **Firebase Cloud Messaging (FCM)**
   - Push bildirimleri
   - Gerçek zamanlı bildirimler

5. **Firebase Cloud Functions**
   - Sunucu tarafı iş mantığı
   - Otomatik bildirim gönderimi
   - Veri doğrulama

### **Üçüncü Parti Entegrasyonlar**

1. **Google Maps SDK**
   - Harita görüntüleme
   - Marker'lar
   - Konum seçimi

2. **Google Places API**
   - Otomatik tamamlama
   - Konum arama
   - Adres detayları

3. **Geolocator**
   - Kullanıcı konumu
   - Mesafe hesaplama
   - Konum izinleri

4. **Image Picker**
   - Galeri erişimi
   - Fotoğraf seçimi

## 📊 Veri Modelleri

### **UserModel**
```dart
- id: String
- email: String
- username: String
- profileImageUrl: String?
- bio: String
- location: String?
- age: int?
- gender: String?
- height: int?
- weight: int?
- level: Level (beginner, intermediate, advanced)
- playStyle: PlayStyle (competitive, casual)
- interestedSports: List<MeetupType>
- averageRating: double
- totalRatings: int
- reliabilityScore: int
- totalMeetupsJoined: int
- followers: List<String>
- following: List<String>
- followersCount: int
- followingCount: int
- badges: List<Badge>
- certificates: List<Certificate>
- createdAt: DateTime
```

### **MeetupModel**
```dart
- id: String
- title: String
- description: String
- type: MeetupType (football, basketball, tennis, yoga, etc.)
- date: DateTime
- locationName: String
- locationAddress: String
- latitude: double
- longitude: double
- maxParticipants: int
- currentParticipants: int
- participantIds: List<String>
- waitlistIds: List<String>
- organizerId: String
- organizerName: String
- organizerImageUrl: String?
- imageUrl: String
- createdAt: DateTime
- status: MeetupStatus
```

### **MessageModel**
```dart
- id: String
- chatId: String
- senderId: String
- senderName: String
- senderImageUrl: String?
- text: String
- timestamp: DateTime
- readBy: List<String>
```

### **NotificationModel**
```dart
- id: String
- userId: String
- type: NotificationType
- title: String
- body: String
- data: Map<String, dynamic>
- isRead: bool
- createdAt: DateTime
```

### **RatingModel**
```dart
- id: String
- ratedUserId: String
- raterUserId: String
- raterName: String
- raterImageUrl: String?
- meetupId: String
- meetupTitle: String
- rating: int (1-5)
- comment: String?
- createdAt: DateTime
```

## 🔄 Gerçek Zamanlı Özellikler

### **Firestore Listeners**
Uygulama, aşağıdaki veriler için gerçek zamanlı dinleyiciler kullanır:

1. **Sohbet Mesajları** (`messages` koleksiyonu)
   - Yeni mesajlar anında görünür
   - Okunmamış sayaç güncellenir

2. **Bildirimler** (`notifications` koleksiyonu)
   - Yeni bildirimler anında gelir
   - Bildirim badge'i güncellenir

3. **Etkinlikler** (`meetups` koleksiyonu)
   - Katılımcı sayısı değişiklikleri
   - Etkinlik durumu güncellemeleri

4. **Kullanıcı Presence** (çevrimiçi durumu)
   - Kullanıcı aktiflik durumu
   - Son görülme zamanı

5. **Kullanıcı İstatistikleri**
   - Ortalama puan değişiklikleri
   - Güvenilirlik skoru güncellemeleri

## 🎨 UI/UX Tasarımı

### **Tema Sistemi**
```dart
AppTheme:
- backgroundLight: #F6F8F6
- surfaceLight: #FFFFFF
- primary: #13EC5B (Neon yeşil)
- textDark: #0F172A
- textMuted: #64748B
- textLight: #94A3B8
- borderLight: #E2E8F0
```

### **Tasarım Prensipleri**
- Modern, minimal arayüz
- Yumuşak geçişler ve animasyonlar
- Tutarlı spacing ve padding
- Erişilebilir renk kontrastları
- Responsive tasarım

### **Navigasyon Yapısı**
```
Bottom Navigation (4 tab):
├── Keşfet (Discovery)
├── Sohbetler (Chats)
├── Oluştur (Create Meetup) - Floating Action Button
└── Profil (Profile)

Diğer Sayfalar:
├── Etkinlik Detay
├── Kullanıcı Profili
├── Değerlendirme Sayfası
├── Bildirimler
├── Ayarlar
├── Geçmiş Etkinlikler
└── Takipçi/Takip Edilenler
```

## 🔐 Güvenlik

### **Firestore Security Rules**
- Kullanıcılar sadece kendi verilerini düzenleyebilir
- Etkinlik organizatörleri etkinliklerini yönetebilir
- Mesajlar sadece katılımcılar tarafından okunabilir
- Değerlendirmeler sadece etkinlik katılımcıları tarafından yapılabilir

### **Veri Doğrulama**
- Email format kontrolü
- Şifre güvenlik gereksinimleri (min 6 karakter)
- Kullanıcı girişi sanitizasyonu
- Tarih/saat validasyonu

## 📈 Performans Optimizasyonları

1. **Image Optimization**
   - Görsel boyutlandırma (max 1024x1024)
   - Kalite sıkıştırma (%85)
   - Lazy loading

2. **Pagination**
   - Etkinlik listelerinde sayfalama
   - Sonsuz scroll
   - Batch loading

3. **Caching**
   - Kullanıcı profil cache
   - Konum cache
   - Harita tile cache

4. **Efficient Queries**
   - Index kullanımı
   - Composite queries
   - Limit ve orderBy optimizasyonları

## 🚀 Öne Çıkan Özellikler

### **1. Akıllı Öneri Sistemi**
`RecommendationService` kullanarak:
- Kullanıcının ilgi alanlarına göre öneriler
- Konum bazlı yakın etkinlikler
- Popülerlik skoruna göre trend etkinlikler
- Yakında başlayacak etkinlikler

### **2. Güvenilirlik Sistemi**
- Katılım oranı takibi
- Değerlendirme ortalaması
- Toplam etkinlik sayısı
- Güvenilirlik skoru hesaplama

### **3. Bekleme Listesi**
- Kontenjan dolduğunda otomatik bekleme listesi
- Kontenjan açıldığında bildirim
- Bekleme listesinden çıkma

### **4. Organizatör Kontrolleri**
- Sohbet modunu değiştirme (herkes/sadece organizatör)
- Katılımcı yönetimi
- Etkinlik düzenleme/iptal

## 🔧 Geliştirme Araçları

### **Dependencies (pubspec.yaml)**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
  firebase_storage: latest
  firebase_messaging: latest
  
  # State Management
  provider: latest
  
  # Navigation
  go_router: latest
  
  # Maps & Location
  google_maps_flutter: latest
  geolocator: latest
  geocoding: latest
  
  # UI
  image_picker: latest
  cached_network_image: latest
  
  # Utilities
  intl: latest
  url_launcher: latest
```

### **Platform Desteği**
- ✅ Android
- ✅ iOS
- ✅ Web (sınırlı)

## 📱 Ekran Akışları

### **Yeni Kullanıcı Akışı**
1. Splash Screen
2. Login/Signup
3. Profil Oluşturma
4. İlgi Alanı Seçimi
5. Ana Sayfa (Keşfet)

### **Etkinlik Oluşturma Akışı**
1. Create Meetup Button
2. Spor Türü Seçimi
3. Detay Girişi (başlık, açıklama, tarih)
4. Konum Seçimi (harita)
5. Görsel Yükleme (opsiyonel)
6. Yayınla

### **Etkinliğe Katılma Akışı**
1. Etkinlik Keşfet/Ara
2. Etkinlik Detayı Görüntüle
3. "Katıl" Butonu
4. Grup Sohbetine Erişim
5. Etkinlik Sonrası Değerlendirme

## 🎯 Gelecek Planlar (Mevcut Spec'ler)

1. **Flutter Map Migration** (`.kiro/specs/flutter-map-migration/`)
   - Google Maps'ten Flutter Map + OpenStreetMap'e geçiş
   - Google Places API korunacak
   - Maliyet optimizasyonu

2. **Dark Map Theme** (`.kiro/specs/dark-map-theme/`)
   - Karanlık tema harita desteği
   - Otomatik tema geçişi

3. **Modern Chat List Redesign** (`.kiro/specs/modern-chat-list-redesign/`)
   - Sohbet listesi yeniden tasarımı
   - Gelişmiş filtreleme

4. **Notification System** (`.kiro/specs/notification-system/`)
   - Gelişmiş bildirim sistemi
   - Bildirim tercihleri

5. **Profile Redesign** (`.kiro/specs/profile-redesign/`)
   - Profil sayfası yeniden tasarımı
   - Daha fazla özelleştirme

6. **Past Events Feature** (`.kiro/specs/past-events-feature/`)
   - Geçmiş etkinlik detayları
   - İstatistikler ve analizler

## 📝 Notlar

- Uygulama Türkçe dilinde geliştirilmiştir
- Firebase Firestore'da Türkçe karakter desteği vardır
- Tüm tarih/saat formatları Türkiye saat dilimine göre ayarlanmıştır
- Google Maps API key'leri platform bazlı yapılandırılmıştır (Android/iOS/Web)

## 🐛 Bilinen Sorunlar

1. `withOpacity` deprecated uyarıları (Flutter 3.x) - `withValues()` kullanılmalı
2. Bazı ekranlarda TODO yorumları (gelecek özellikler için)
3. BuildContext async gap uyarıları (mounted check gerekli)

---

**Son Güncelleme:** 4 Şubat 2026
**Flutter Versiyonu:** 3.x
**Dart Versiyonu:** 3.x
**Minimum SDK:** Android 21+ / iOS 12+
