import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('ar'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sporsal'**
  String get appTitle;

  /// No description provided for @findSportPartner.
  ///
  /// In tr, this message translates to:
  /// **'Spor Arkadaşını Bul'**
  String get findSportPartner;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @loginToAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza giriş yapın'**
  String get loginToAccount;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In tr, this message translates to:
  /// **'ornek@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta girin'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordTooShort;

  /// No description provided for @showPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get hidePassword;

  /// No description provided for @noAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get signUp;

  /// No description provided for @chat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get chat;

  /// No description provided for @meetupNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Buluşma bulunamadı'**
  String get meetupNotFound;

  /// No description provided for @chatInfoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet bilgisi bulunamadı'**
  String get chatInfoNotFound;

  /// No description provided for @userNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı'**
  String get userNotFound;

  /// No description provided for @userInfoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bilgisi bulunamadı'**
  String get userInfoNotFound;

  /// No description provided for @eventInfoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bilgisi bulunamadı'**
  String get eventInfoNotFound;

  /// No description provided for @infoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi bulunamadı'**
  String get infoNotFound;

  /// No description provided for @eventNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bulunamadı'**
  String get eventNotFound;

  /// No description provided for @streamNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Yayın bulunamadı'**
  String get streamNotFound;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfile;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @notificationSettings.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get notificationSettings;

  /// No description provided for @pastMeetups.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Etkinlikler'**
  String get pastMeetups;

  /// No description provided for @organizerCannotLeave.
  ///
  /// In tr, this message translates to:
  /// **'Organizatör kendi etkinliğinden ayrılamaz'**
  String get organizerCannotLeave;

  /// No description provided for @notParticipant.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinliğe katılmadınız'**
  String get notParticipant;

  /// No description provided for @alreadyJoined.
  ///
  /// In tr, this message translates to:
  /// **'Zaten bu etkinliğe katıldınız'**
  String get alreadyJoined;

  /// No description provided for @eventFull.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik dolu'**
  String get eventFull;

  /// No description provided for @invalidTeamSelection.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz takım seçimi'**
  String get invalidTeamSelection;

  /// No description provided for @invalidPositionSelection.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz pozisyon seçimi'**
  String get invalidPositionSelection;

  /// No description provided for @positionTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu pozisyon zaten dolu. Lütfen başka bir pozisyon seçin.'**
  String get positionTaken;

  /// No description provided for @selectPositionForFootball.
  ///
  /// In tr, this message translates to:
  /// **'Bu futbol etkinligine katilmak icin pozisyon secmelisiniz'**
  String get selectPositionForFootball;

  /// No description provided for @sectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get sectionAccount;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilerinizi güncelleyin'**
  String get editProfileSubtitle;

  /// No description provided for @sectionPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get sectionPrivacy;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap güvenliğinizi koruyun'**
  String get changePasswordSubtitle;

  /// No description provided for @privacySettings.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Ayarları'**
  String get privacySettings;

  /// No description provided for @privacySettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kim sizi görebilir?'**
  String get privacySettingsSubtitle;

  /// No description provided for @sectionNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get sectionNotifications;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi bildirimleri almak istersiniz?'**
  String get notificationSettingsSubtitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get sectionAppearance;

  /// No description provided for @mapStyle.
  ///
  /// In tr, this message translates to:
  /// **'Harita Stili'**
  String get mapStyle;

  /// No description provided for @appLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get appLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın görüntülendiği dili seçin.'**
  String get appLanguageSubtitle;

  /// No description provided for @sectionSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get sectionSupport;

  /// No description provided for @helpSupport.
  ///
  /// In tr, this message translates to:
  /// **'Yardım & Destek'**
  String get helpSupport;

  /// No description provided for @aboutApp.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutApp;

  /// No description provided for @sectionAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim'**
  String get sectionAdmin;

  /// No description provided for @adminActions.
  ///
  /// In tr, this message translates to:
  /// **'Admin İşlemleri'**
  String get adminActions;

  /// No description provided for @adminActionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bakım ve yönetim araçları'**
  String get adminActionsSubtitle;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmContent.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkmak istediğinize emin misiniz?'**
  String get logoutConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @passwordChangeSoon.
  ///
  /// In tr, this message translates to:
  /// **'Şifre değiştirme yakında eklenecek!'**
  String get passwordChangeSoon;

  /// No description provided for @privacySettingsSoon.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ayarları yakında eklenecek!'**
  String get privacySettingsSoon;

  /// No description provided for @helpSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yardım sayfası yakında eklenecek!'**
  String get helpSoon;

  /// No description provided for @navFeed.
  ///
  /// In tr, this message translates to:
  /// **'Akış'**
  String get navFeed;

  /// No description provided for @navChats.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get navChats;

  /// No description provided for @navCreate.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get navCreate;

  /// No description provided for @navVenues.
  ///
  /// In tr, this message translates to:
  /// **'Mekanlar'**
  String get navVenues;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get navPhoto;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
