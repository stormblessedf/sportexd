# SPORSAL - Spor Etkinlik Koordinasyon Uygulaması
## Kapsamlı Proje Özeti

---

## 📱 UYGULAMA HAKKINDA

**Sporsal**, kullanıcıların spor etkinlikleri oluşturmasına, keşfetmesine ve katılmasına olanak tanıyan sosyal bir mobil uygulamadır. Flutter ile geliştirilmiş, Firebase backend altyapısı kullanan, cross-platform (iOS, Android, Web) bir çözümdür.

### 🎯 Temel Amaç
Spor yapmak isteyen insanları bir araya getirmek, etkinlik organizasyonunu kolaylaştırmak ve güvenilir bir topluluk oluşturmak.

---

## 🏗️ TEKNİK MİMARİ

### **Teknoloji Stack**
- **Framework**: Flutter 3.10.7
- **Dil**: Dart
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **State Management**: Provider
- **Routing**: GoRouter 17.0.1
- **Maps**: Google Maps Flutter
- **Bildirimler**: Firebase Cloud Messaging + Flutter Local Notifications

### **Proje Yapısı**
```
lib/
├── core/                    # Çekirdek işlevsellik
│   ├── models/             # Veri modelleri
│   ├── services/           # İş mantığı servisleri
│   ├── utils/              # Yardımcı fonksiyonlar
│   └── widgets/            # Paylaşılan widget'lar
├── features/               # Özellik modülleri
│   ├── auth/              # Kimlik doğrulama
│   ├── discovery/         # Etkinlik keşfi
│   ├── meetups/           # Etkinlik yönetimi
│   ├── chat/              # Sohbet sistemi
│   ├── profile/           # Kullanıcı profili
│   └── notifications/     # Bildirim sistemi
└── theme/                 # Tema ve renkler
```

---

## ✨ ANA ÖZELLİKLER

### 1. 🔐 **Kimlik Doğrulama Sistemi**
- Email/şifre ile kayıt ve giriş
- Firebase Authentication entegrasyonu
- Profil oluşturma ve düzenleme
- Kullanıcı oturum yönetimi

**Ekranlar:**
- `LoginScreen` - Giriş ekranı
- `SignUpScreen` - Kayıt ekranı
- `CreateProfileScreen` - İlk profil oluşturma
- `EditProfileScreen` - Profil düzenleme

---

### 2. 🏃 **Etkinlik Yönetimi**

#### **Etkinlik Oluşturma**
- Spor türü seçimi (Futbol, Basketbol, Tenis, Koşu, vb.)
- Konum seçimi (Google Maps entegrasyonu)
- Tarih ve saat belirleme
- Katılımcı sayısı limiti
- Seviye ve oyun stili tercihleri

#### **Etkinlik Keşfi**
- Ana sayfa feed'i
- Harita görünümü (yakındaki etkinlikler)
- Filtreleme ve arama
- Gerçek zamanlı güncellemeler

#### **Etkinlik Detayları**
- Tam etkinlik bilgileri
- Katılımcı listesi
- Konum haritası
- Organizatör profili
- Katılım butonu

**Ekranlar:**
- `DiscoveryPage` - Ana keşif sayfası
- `CreateMeetupScreen` - Etkinlik oluşturma
- `MeetupDetailScreen` - Etkinlik detayları
- `NearbyMeetupsMapScreen` - Harita görünümü
- `PastMeetupsScreen` - Geçmiş etkinlikler

**Servisler:**
- `MeetupService` - Etkinlik CRUD işlemleri
- `LocationService` - Konum servisleri
- `PlacesService` - Google Places API
- `SearchService` - Arama ve filtreleme

---

### 3. 💬 **Sohbet Sistemi**

#### **Grup Sohbetleri**
- Her etkinlik için otomatik grup sohbeti
- Gerçek zamanlı mesajlaşma
- Mesaj geçmişi
- Katılımcı listesi

#### **Sohbet Listesi**
- Aktif sohbetler sekmesi
- Geçmiş sohbetler sekmesi
- Son mesaj önizlemesi
- Okunmamış mesaj göstergesi

**Ekranlar:**
- `MyChatsScreen` - Sohbet listesi
- `ChatScreen` - Sohbet detayı

**Servisler:**
- `ChatService` - Mesajlaşma yönetimi
- `PresenceService` - Kullanıcı çevrimiçi durumu

**Veri Modelleri:**
- `MessageModel` - Mesaj yapısı
- `ChatUpdateModel` - Sohbet güncellemeleri

---

### 4. 👤 **Kullanıcı Profili Sistemi**

#### **Profil Özellikleri**
- Profil fotoğrafı
- Kullanıcı adı ve biyografi
- Konum bilgisi
- Spor tercihleri
- İstatistikler (toplam etkinlik, güvenilirlik skoru)
- Rozetler ve sertifikalar

#### **Sosyal Özellikler**
- Takip et/takipten çık
- Takipçi/takip edilen listesi
- Kullanıcı puanlama sistemi
- Değerlendirme ve yorumlar

#### **Puanlama Sistemi**
- 5 yıldızlı değerlendirme
- Yorum yazma
- Puan dağılımı grafiği
- Ortalama puan hesaplama
- Güvenilirlik skoru

**Ekranlar:**
- `ProfileScreen` - Profil görüntüleme
- `EditProfileScreen` - Profil düzenleme
- `FollowersFollowingScreen` - Takipçi/takip listesi
- `UserRatingsPage` - Kullanıcı değerlendirmeleri
- `RateUserScreen` - Kullanıcı puanlama
- `SelectMeetupScreen` - Etkinlik seçimi (puanlama için)
- `RateMembersScreen` - Toplu katılımcı puanlama

**Servisler:**
- `AuthService` - Kullanıcı yönetimi
- `RatingService` - Puanlama işlemleri
- `ReliabilityService` - Güvenilirlik hesaplama

**Veri Modelleri:**
- `UserModel` - Kullanıcı bilgileri
- `RatingModel` - Değerlendirme yapısı
- `RatingDistribution` - Puan dağılımı

---

### 5. 🔔 **Bildirim Sistemi**

#### **Bildirim Türleri**
- Etkinlik hatırlatmaları (1 saat önce)
- Etkinlik güncellemeleri
- Etkinlik iptalleri
- Yeni katılımcı bildirimleri
- Sohbet mesajları
- Kapasite doldu bildirimleri

#### **Bildirim Yönetimi**
- Bildirim listesi ekranı
- Okunmamış sayacı
- Bildirim ayarları
- Sessiz saatler
- Bildirim türü tercihleri

**Ekranlar:**
- `NotificationsScreen` - Bildirim listesi
- `NotificationSettingsScreen` - Bildirim ayarları

**Servisler:**
- `NotificationService` - Bildirim yönetimi
- Firebase Cloud Messaging entegrasyonu

**Veri Modelleri:**
- `NotificationModel` - Bildirim yapısı
- `NotificationPreferences` - Kullanıcı tercihleri

---

### 6. 🗺️ **Konum ve Harita Özellikleri**

#### **Konum Servisleri**
- Kullanıcı konumu tespiti
- Yakındaki etkinlikler
- Mesafe hesaplama
- Adres arama (Google Places)
- Geocoding/Reverse Geocoding

#### **Harita Görünümü**
- Google Maps entegrasyonu
- Özel marker'lar
- Etkinlik konumları
- Navigasyon desteği

**Servisler:**
- `LocationService` - Konum yönetimi
- `PlacesService` - Yer arama

**Utilities:**
- `CustomMarkerGenerator` - Özel marker oluşturma
- `MapStyle` - Harita stil ayarları

---

### 7. 🎨 **Tasarım Sistemi**

#### **Renk Paleti**
- **Primary**: #13EC5B (Yeşil)
- **Background Light**: #F6F8F6
- **Surface Light**: #FFFFFF
- **Text Dark**: #0F172A
- **Text Muted**: #64748B
- **Border Light**: #E2E8F0

#### **Tipografi**
- **Font**: Lexend (Google Fonts)
- Modern, okunabilir, profesyonel

#### **Bileşenler**
- Özel butonlar
- Kart tasarımları
- Form elemanları
- Chip'ler ve badge'ler
- Bottom navigation
- App bar'lar

**Dosyalar:**
- `app_theme.dart` - Ana tema tanımları
- `app_colors.dart` - Renk sabitleri

---

## 📊 VERİ MODELLERİ

### **Temel Modeller**

#### **UserModel**
```dart
- id, username, email
- profileImageUrl, bio
- location, age, gender
- height, weight, level, playStyle
- interestedSports
- followers, following, followersCount, followingCount
- averageRating, totalRatings, reliabilityScore
- totalMeetupsJoined, totalMeetupsOrganized
- badges, certificates
```

#### **MeetupModel**
```dart
- id, title, description
- type (SportType enum)
- date, locationName, locationAddress
- latitude, longitude
- organizerId, organizerName, organizerImageUrl
- currentParticipants, maxParticipants
- participantIds
- level, playStyle
- imageUrl
```

#### **MessageModel**
```dart
- id, chatId
- senderId, senderName
- text, timestamp
- type (text, image, system)
```

#### **RatingModel**
```dart
- id, raterId, raterName
- ratedUserId, meetupId
- rating (1-5), comment
- timestamp
```

#### **NotificationModel**
```dart
- id, userId
- type, title, message
- timestamp, isRead
- relatedId, metadata
```

---

## 🔧 SERVİSLER

### **Core Services**

1. **AuthService**
   - Kullanıcı kaydı ve girişi
   - Profil yönetimi
   - Takip sistemi
   - Oturum yönetimi

2. **MeetupService**
   - Etkinlik CRUD işlemleri
   - Katılım yönetimi
   - Geçmiş etkinlikler
   - Filtreleme ve arama

3. **ChatService**
   - Mesaj gönderme/alma
   - Sohbet geçmişi
   - Okunmamış sayacı
   - Gerçek zamanlı güncellemeler

4. **RatingService**
   - Kullanıcı puanlama
   - Değerlendirme yönetimi
   - Ortalama hesaplama
   - Puan dağılımı

5. **NotificationService**
   - FCM token yönetimi
   - Bildirim gönderme
   - Bildirim tercihleri
   - Gerçek zamanlı dinleme

6. **LocationService**
   - Konum izinleri
   - Mevcut konum
   - Mesafe hesaplama
   - Geocoding

7. **PresenceService**
   - Çevrimiçi/çevrimdışı durumu
   - Son görülme
   - Gerçek zamanlı durum

8. **ReliabilityService**
   - Güvenilirlik skoru hesaplama
   - Katılım geçmişi analizi

9. **CacheService**
   - Veri önbellekleme
   - Performans optimizasyonu

10. **FilterService**
    - Etkinlik filtreleme
    - Arama kriterleri

11. **RecommendationService**
    - Öneri algoritması
    - Kişiselleştirilmiş içerik

12. **SearchService**
    - Metin arama
    - Filtreleme

---

## 🛠️ YARDIMCI ARAÇLAR (UTILITIES)

1. **RelativeTimestamp**
   - Göreceli zaman formatı
   - "2 saat önce", "Dün", vb.

2. **TimeFormatter**
   - Tarih/saat formatlama
   - Türkçe yerelleştirme

3. **RatingValidation**
   - Puan doğrulama
   - Yetki kontrolü

4. **RatingSorting**
   - Değerlendirme sıralama
   - Filtreleme

5. **CustomMarkerGenerator**
   - Harita marker'ları
   - Özel tasarımlar

6. **MapStyle**
   - Harita görünümü
   - Stil tanımları

7. **AdminActions**
   - Yönetici araçları
   - Bakım işlemleri

---

## 📱 EKRAN AKIŞI

### **Kullanıcı Yolculuğu**

1. **İlk Giriş**
   ```
   Splash → Login → SignUp → CreateProfile → Home
   ```

2. **Ana Akış**
   ```
   Home (Discovery) ↔ Chats ↔ Create ↔ Profile
   ```

3. **Etkinlik Akışı**
   ```
   Discovery → MeetupDetail → Join → Chat
   ```

4. **Profil Akışı**
   ```
   Profile → EditProfile / UserRatings / Followers
   ```

5. **Puanlama Akışı**
   ```
   PastMeetups → SelectMeetup → RateUser
   ```

---

## 🔐 GÜVENLİK ÖZELLİKLERİ

1. **Firebase Authentication**
   - Güvenli kimlik doğrulama
   - Email doğrulama
   - Şifre sıfırlama

2. **Firestore Security Rules**
   - Veri erişim kontrolü
   - Kullanıcı yetkilendirme

3. **Storage Security**
   - Dosya yükleme kontrolü
   - Boyut limitleri

4. **Input Validation**
   - Form doğrulama
   - XSS koruması

---

## 📈 PERFORMANS OPTİMİZASYONU

1. **Caching**
   - CachedNetworkImage
   - Veri önbellekleme
   - Shared Preferences

2. **Lazy Loading**
   - Sayfalama
   - Gerektiğinde yükleme

3. **Stream Optimization**
   - Firestore snapshot'ları
   - Gerçek zamanlı güncellemeler

4. **Image Optimization**
   - Sıkıştırma
   - Boyut limitleri
   - Progressive loading

---

## 🌐 PLATFORM DESTEĞİ

- ✅ **iOS** - Tam destek
- ✅ **Android** - Tam destek
- ✅ **Web** - Tam destek (DevicePreview ile test)

---

## 📦 BAĞIMLILIKLAR

### **Ana Paketler**
- `firebase_core` - Firebase temel
- `firebase_auth` - Kimlik doğrulama
- `cloud_firestore` - Veritabanı
- `firebase_storage` - Dosya depolama
- `firebase_messaging` - Push bildirimleri
- `google_maps_flutter` - Harita
- `go_router` - Navigasyon
- `provider` - State management
- `google_fonts` - Tipografi
- `image_picker` - Resim seçimi
- `geolocator` - Konum
- `cached_network_image` - Resim önbellekleme

---

## 🚀 GELECEK ÖZELLİKLER (SPEC'LER)

### **1. Katılımcı Profil Önizleme**
- Etkinlik detayında katılımcı avatarları
- Tıklanabilir profil kartları
- Hızlı profil önizlemesi

### **2. Modern Sohbet Listesi Redesign**
- Büyük profil resimleri
- Aktivite ikon rozetleri
- Son mesaj önizlemesi
- Göreceli zaman damgaları
- Okunmamış göstergeleri

### **3. Bildirim Sistemi**
- Kapsamlı bildirim altyapısı
- FCM entegrasyonu
- Bildirim tercihleri
- Sessiz saatler

---

## 📊 İSTATİSTİKLER

### **Kod Metrikleri**
- **Toplam Ekran**: 20+
- **Servis Sayısı**: 13
- **Veri Modeli**: 12+
- **Widget**: 50+
- **Satır Kodu**: ~15,000+

### **Özellik Sayısı**
- **Ana Özellik**: 7
- **Alt Özellik**: 30+
- **Ekran**: 20+
- **API Entegrasyonu**: 5+

---

## 🎯 BAŞARILAR

✅ **Tam Firebase Entegrasyonu**
✅ **Gerçek Zamanlı Güncellemeler**
✅ **Kapsamlı Kullanıcı Profili**
✅ **Sosyal Özellikler (Takip, Puanlama)**
✅ **Harita ve Konum Servisleri**
✅ **Push Bildirimler**
✅ **Modern UI/UX Tasarımı**
✅ **Cross-Platform Destek**
✅ **Güvenlik ve Performans**
✅ **Ölçeklenebilir Mimari**

---

## 🔄 SÜREKLI GELİŞTİRME

### **Aktif Spec'ler**
1. Participant Profile Preview
2. Modern Chat List Redesign
3. Notification System
4. Past Events Feature
5. Profile Redesign
6. Discovery Page Enhancement

### **Planlanan İyileştirmeler**
- Performans optimizasyonları
- UI/UX iyileştirmeleri
- Yeni özellikler
- Test coverage artırma
- Dokümantasyon

---

## 📝 SONUÇ

**Sporsal**, modern bir spor etkinlik koordinasyon platformudur. Flutter'ın gücünü Firebase'in ölçeklenebilirliği ile birleştirerek, kullanıcılara sorunsuz bir deneyim sunar.

### **Temel Güçlü Yönler:**
- 🎨 Modern ve kullanıcı dostu tasarım
- ⚡ Gerçek zamanlı güncellemeler
- 🔒 Güvenli ve güvenilir
- 📱 Cross-platform destek
- 🚀 Ölçeklenebilir mimari
- 💬 Kapsamlı sosyal özellikler
- 🗺️ Gelişmiş konum servisleri
- 🔔 Akıllı bildirim sistemi

### **Hedef Kitle:**
- Spor yapmak isteyen bireyler
- Etkinlik organizatörleri
- Spor toplulukları
- Sosyal spor grupları

### **Değer Önerisi:**
Sporsal, insanları spor etkinlikleri etrafında bir araya getirerek, sağlıklı yaşam ve sosyal etkileşimi teşvik eder. Güvenilir bir topluluk oluşturarak, kullanıcıların güvenle etkinliklere katılmasını sağlar.

---

**Geliştirme Durumu**: 🟢 Aktif Geliştirme
**Platform**: iOS, Android, Web
**Teknoloji**: Flutter + Firebase
**Versiyon**: 1.0.0+1

---

*Bu özet, Sporsal uygulamasının mevcut durumunu ve gelecek planlarını kapsamaktadır.*
