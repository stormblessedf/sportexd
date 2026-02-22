// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Sporsal';

  @override
  String get findSportPartner => 'Spor Arkadaşını Bul';

  @override
  String get login => 'Giriş Yap';

  @override
  String get loginToAccount => 'Hesabınıza giriş yapın';

  @override
  String get email => 'E-posta';

  @override
  String get emailHint => 'ornek@email.com';

  @override
  String get emailRequired => 'E-posta adresi gerekli';

  @override
  String get emailInvalid => 'Geçerli bir e-posta girin';

  @override
  String get password => 'Şifre';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get noAccount => 'Hesabın yok mu?';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get chat => 'Sohbet';

  @override
  String get meetupNotFound => 'Buluşma bulunamadı';

  @override
  String get chatInfoNotFound => 'Sohbet bilgisi bulunamadı';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String get userInfoNotFound => 'Kullanıcı bilgisi bulunamadı';

  @override
  String get eventInfoNotFound => 'Etkinlik bilgisi bulunamadı';

  @override
  String get infoNotFound => 'Bilgi bulunamadı';

  @override
  String get eventNotFound => 'Etkinlik bulunamadı';

  @override
  String get streamNotFound => 'Yayın bulunamadı';

  @override
  String get settings => 'Ayarlar';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get pastMeetups => 'Geçmiş Etkinlikler';

  @override
  String get organizerCannotLeave =>
      'Organizatör kendi etkinliğinden ayrılamaz';

  @override
  String get notParticipant => 'Bu etkinliğe katılmadınız';

  @override
  String get alreadyJoined => 'Zaten bu etkinliğe katıldınız';

  @override
  String get eventFull => 'Etkinlik dolu';

  @override
  String get invalidTeamSelection => 'Geçersiz takım seçimi';

  @override
  String get invalidPositionSelection => 'Geçersiz pozisyon seçimi';

  @override
  String get positionTaken =>
      'Bu pozisyon zaten dolu. Lütfen başka bir pozisyon seçin.';

  @override
  String get selectPositionForFootball =>
      'Bu futbol etkinligine katilmak icin pozisyon secmelisiniz';
}
