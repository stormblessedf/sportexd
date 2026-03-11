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
  /// **'Bu futbol etkinliğine katılmak için pozisyon seçmelisiniz'**
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

  /// No description provided for @adminRatingsRecalculateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı! Tüm kullanıcı puanları güncellendi.'**
  String get adminRatingsRecalculateSuccess;

  /// No description provided for @adminPartnershipMigrationSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı! Partnership migration tamamlandı. Geçmiş etkinliklerdeki kullanıcı çiftleri partner olarak eklendi.'**
  String get adminPartnershipMigrationSuccess;

  /// No description provided for @adminRecalculateButton.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Hesapla'**
  String get adminRecalculateButton;

  /// No description provided for @adminDeleteImageLessButton.
  ///
  /// In tr, this message translates to:
  /// **'Görselsiz Etkinlikleri Sil'**
  String get adminDeleteImageLessButton;

  /// No description provided for @adminPartnershipMigrationButton.
  ///
  /// In tr, this message translates to:
  /// **'Partnership Migration Başlat'**
  String get adminPartnershipMigrationButton;

  /// No description provided for @adminMeetupRecalculateButton.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Sayaçlarını Hesapla'**
  String get adminMeetupRecalculateButton;

  /// No description provided for @adminReliabilityRecalculateButton.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilirlikleri Güncelle'**
  String get adminReliabilityRecalculateButton;

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

  /// No description provided for @createAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get createAccount;

  /// No description provided for @signUpSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Spor arkadaşlarınla tanışmaya hazır mısın?'**
  String get signUpSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi tekrar girin'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMinChars.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get passwordMinChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta adresi zaten kullanımda.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre çok zayıf. En az 6 karakter olmalı.'**
  String get weakPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz e-posta adresi.'**
  String get invalidEmail;

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get alreadyHaveAccount;

  /// No description provided for @emailAccessibility.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi giriş alanı'**
  String get emailAccessibility;

  /// No description provided for @passwordAccessibility.
  ///
  /// In tr, this message translates to:
  /// **'Şifre giriş alanı'**
  String get passwordAccessibility;

  /// No description provided for @explore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get explore;

  /// No description provided for @following.
  ///
  /// In tr, this message translates to:
  /// **'Takip Edilenler'**
  String get following;

  /// No description provided for @live.
  ///
  /// In tr, this message translates to:
  /// **'Canlı'**
  String get live;

  /// No description provided for @exploreSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki aktiviteleri keşfet'**
  String get exploreSubtitle;

  /// No description provided for @followingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Takip ettiğin kişilerin aktiviteleri'**
  String get followingSubtitle;

  /// No description provided for @liveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktif etkinliklerden canlı paylaşımlar'**
  String get liveSubtitle;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get errorOccurred;

  /// No description provided for @errorOccurredWith.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu: {error}'**
  String errorOccurredWith(String error);

  /// No description provided for @noEventsFollowing.
  ///
  /// In tr, this message translates to:
  /// **'Takip ettiğin kişiler henüz etkinlik oluşturmamış'**
  String get noEventsFollowing;

  /// No description provided for @noEventsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik yok'**
  String get noEventsYet;

  /// No description provided for @checkExploreTab.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet sekmesine göz atabilirsin'**
  String get checkExploreTab;

  /// No description provided for @createFirstEvent.
  ///
  /// In tr, this message translates to:
  /// **'İlk etkinliği sen oluştur!'**
  String get createFirstEvent;

  /// No description provided for @loginToViewChats.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetleri görmek için giriş yapın'**
  String get loginToViewChats;

  /// No description provided for @loginToViewChatsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza giriş yaparak etkinlik sohbetlerinize ulaşabilirsiniz'**
  String get loginToViewChatsSubtitle;

  /// No description provided for @filterChats.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetleri Filtrele'**
  String get filterChats;

  /// No description provided for @bySportType.
  ///
  /// In tr, this message translates to:
  /// **'Spor Türüne Göre'**
  String get bySportType;

  /// No description provided for @sortByDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihe Göre Sırala'**
  String get sortByDate;

  /// No description provided for @activeTab.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get activeTab;

  /// No description provided for @pastTab.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get pastTab;

  /// No description provided for @dmTab.
  ///
  /// In tr, this message translates to:
  /// **'DM'**
  String get dmTab;

  /// No description provided for @noDmYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz direkt mesajınız yok'**
  String get noDmYet;

  /// No description provided for @sendMessageToPartners.
  ///
  /// In tr, this message translates to:
  /// **'Spor partnerlerinize mesaj gönderin'**
  String get sendMessageToPartners;

  /// No description provided for @userFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get userFallback;

  /// No description provided for @noMessagesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok'**
  String get noMessagesYet;

  /// No description provided for @deleteMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı Sil'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesajı silmek istediğinizden emin misiniz?'**
  String get deleteMessageConfirm;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @reply.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtla'**
  String get reply;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @messageCopied.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj kopyalandı'**
  String get messageCopied;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @editFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj düzenlenemedi.'**
  String get editFailed;

  /// No description provided for @sendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilemedi.'**
  String get sendFailed;

  /// No description provided for @loginToJoinChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete katılmak için giriş yapmalısınız.'**
  String get loginToJoinChat;

  /// No description provided for @openToAll.
  ///
  /// In tr, this message translates to:
  /// **'Herkese Aç'**
  String get openToAll;

  /// No description provided for @organizerOnly.
  ///
  /// In tr, this message translates to:
  /// **'Sadece Yönetici'**
  String get organizerOnly;

  /// No description provided for @sendAnnouncement.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru Gönder'**
  String get sendAnnouncement;

  /// No description provided for @organizerModeActive.
  ///
  /// In tr, this message translates to:
  /// **'Sadece yönetici modu aktif'**
  String get organizerModeActive;

  /// No description provided for @onlyOrganizerCanSend.
  ///
  /// In tr, this message translates to:
  /// **'Sadece yönetici mesaj gönderebilir'**
  String get onlyOrganizerCanSend;

  /// No description provided for @everyoneCanSend.
  ///
  /// In tr, this message translates to:
  /// **'Herkes mesaj gönderebilir'**
  String get everyoneCanSend;

  /// No description provided for @chatReadOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinlik sona erdi. Sohbet salt okunur.'**
  String get chatReadOnly;

  /// No description provided for @noMessagesFirst.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok. İlk mesajı sen at!'**
  String get noMessagesFirst;

  /// No description provided for @cannotSendMessages.
  ///
  /// In tr, this message translates to:
  /// **'Bu sohbete mesaj gönderilemez'**
  String get cannotSendMessages;

  /// No description provided for @editing.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleniyor'**
  String get editing;

  /// No description provided for @editMessageHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı düzenle...'**
  String get editMessageHint;

  /// No description provided for @writeMessageHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get writeMessageHint;

  /// No description provided for @announcementHint.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru metnini yazın...'**
  String get announcementHint;

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @edited.
  ///
  /// In tr, this message translates to:
  /// **'düzenlendi'**
  String get edited;

  /// No description provided for @messageDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesaj silindi'**
  String get messageDeleted;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @retryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retryButton;

  /// No description provided for @profileLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi: {error}'**
  String profileLoadFailed(String error);

  /// No description provided for @sessionNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı oturumu bulunamadı'**
  String get sessionNotFound;

  /// No description provided for @profilePicUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil resmi güncellendi!'**
  String get profilePicUpdated;

  /// No description provided for @errorWithMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @pastEventsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Etkinliklerim'**
  String get pastEventsTitle;

  /// No description provided for @partnershipAction.
  ///
  /// In tr, this message translates to:
  /// **'Partnerlik Yap'**
  String get partnershipAction;

  /// No description provided for @settingsMenu.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsMenu;

  /// No description provided for @earnedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Kazanıldı'**
  String get earnedBadge;

  /// No description provided for @createProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil Oluştur'**
  String get createProfile;

  /// No description provided for @addProfilePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Profil Fotoğrafı Ekle'**
  String get addProfilePhoto;

  /// No description provided for @usernameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı'**
  String get usernameLabel;

  /// No description provided for @usernameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı gerekli'**
  String get usernameRequired;

  /// No description provided for @usernameHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adınız'**
  String get usernameHint;

  /// No description provided for @minThreeChars.
  ///
  /// In tr, this message translates to:
  /// **'En az 3 karakter olmalı'**
  String get minThreeChars;

  /// No description provided for @aboutSection.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutSection;

  /// No description provided for @aboutHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendinizden bahsedin...'**
  String get aboutHint;

  /// No description provided for @personalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get personalInfo;

  /// No description provided for @age.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get age;

  /// No description provided for @height.
  ///
  /// In tr, this message translates to:
  /// **'Boy (cm)'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo (kg)'**
  String get weight;

  /// No description provided for @required.
  ///
  /// In tr, this message translates to:
  /// **'Gerekli'**
  String get required;

  /// No description provided for @invalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz'**
  String get invalid;

  /// No description provided for @gender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get gender;

  /// No description provided for @selectGender.
  ///
  /// In tr, this message translates to:
  /// **'Seçiniz'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get male;

  /// No description provided for @female.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get female;

  /// No description provided for @preferNotToSay.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek İstemiyorum'**
  String get preferNotToSay;

  /// No description provided for @location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get location;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// No description provided for @level.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get level;

  /// No description provided for @beginner.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get advanced;

  /// No description provided for @playStyle.
  ///
  /// In tr, this message translates to:
  /// **'Oyun Stili'**
  String get playStyle;

  /// No description provided for @casual.
  ///
  /// In tr, this message translates to:
  /// **'Rahat'**
  String get casual;

  /// No description provided for @competitive.
  ///
  /// In tr, this message translates to:
  /// **'Rekabetçi'**
  String get competitive;

  /// No description provided for @interestedSports.
  ///
  /// In tr, this message translates to:
  /// **'İlgilendiğin Spor Dalları'**
  String get interestedSports;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In tr, this message translates to:
  /// **'En az bir tane seç'**
  String get selectAtLeastOne;

  /// No description provided for @mustSelectOneSport.
  ///
  /// In tr, this message translates to:
  /// **'En az bir spor dalı seçmelisiniz'**
  String get mustSelectOneSport;

  /// No description provided for @sessionNotFoundLogin.
  ///
  /// In tr, this message translates to:
  /// **'Oturum bulunamadı. Lütfen tekrar giriş yapın.'**
  String get sessionNotFoundLogin;

  /// No description provided for @profileCreated.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla oluşturuldu!'**
  String get profileCreated;

  /// No description provided for @completeProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Tamamla'**
  String get completeProfile;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu Hafta'**
  String get thisWeek;

  /// No description provided for @earlier.
  ///
  /// In tr, this message translates to:
  /// **'Daha Önce'**
  String get earlier;

  /// No description provided for @markAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Okundu İşaretle'**
  String get markAllRead;

  /// No description provided for @allNotificationsRead.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bildirimler okundu olarak işaretlendi'**
  String get allNotificationsRead;

  /// No description provided for @noNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Yok'**
  String get noNotifications;

  /// No description provided for @newNotificationsHere.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bildirimler burada görünecek'**
  String get newNotificationsHere;

  /// No description provided for @eventLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik yüklenirken hata oluştu'**
  String get eventLoadError;

  /// No description provided for @justNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count}dk önce'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count}sa önce'**
  String hoursAgo(int count);

  /// No description provided for @sportRunning.
  ///
  /// In tr, this message translates to:
  /// **'Koşu'**
  String get sportRunning;

  /// No description provided for @sportCycling.
  ///
  /// In tr, this message translates to:
  /// **'Bisiklet'**
  String get sportCycling;

  /// No description provided for @sportFitness.
  ///
  /// In tr, this message translates to:
  /// **'Fitness'**
  String get sportFitness;

  /// No description provided for @sportYoga.
  ///
  /// In tr, this message translates to:
  /// **'Yoga'**
  String get sportYoga;

  /// No description provided for @sportTennis.
  ///
  /// In tr, this message translates to:
  /// **'Tenis'**
  String get sportTennis;

  /// No description provided for @sportFootball.
  ///
  /// In tr, this message translates to:
  /// **'Futbol'**
  String get sportFootball;

  /// No description provided for @sportBasketball.
  ///
  /// In tr, this message translates to:
  /// **'Basketbol'**
  String get sportBasketball;

  /// No description provided for @sportVolleyball.
  ///
  /// In tr, this message translates to:
  /// **'Voleybol'**
  String get sportVolleyball;

  /// No description provided for @sportSwimming.
  ///
  /// In tr, this message translates to:
  /// **'Yüzme'**
  String get sportSwimming;

  /// No description provided for @sportHiking.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş'**
  String get sportHiking;

  /// No description provided for @sportBoxing.
  ///
  /// In tr, this message translates to:
  /// **'Boks'**
  String get sportBoxing;

  /// No description provided for @sportOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get sportOther;

  /// No description provided for @createEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Oluştur'**
  String get createEvent;

  /// No description provided for @selectSport.
  ///
  /// In tr, this message translates to:
  /// **'Spor Seç'**
  String get selectSport;

  /// No description provided for @dateAndTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih & Saat'**
  String get dateAndTime;

  /// No description provided for @startTime.
  ///
  /// In tr, this message translates to:
  /// **'BAŞLANGIÇ'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In tr, this message translates to:
  /// **'BİTİŞ'**
  String get endTime;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @endTimeMustBeAfterStart.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş saati başlangıç saatinden sonra olmalı'**
  String get endTimeMustBeAfterStart;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen konum seçin'**
  String get pleaseSelectLocation;

  /// No description provided for @notLoggedIn.
  ///
  /// In tr, this message translates to:
  /// **'Oturum açık değil'**
  String get notLoggedIn;

  /// No description provided for @eventCreated.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik oluşturuldu!'**
  String get eventCreated;

  /// No description provided for @monthJan.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get monthDec;

  /// No description provided for @loginToJoin.
  ///
  /// In tr, this message translates to:
  /// **'Katılmak için giriş yapmalısınız.'**
  String get loginToJoin;

  /// No description provided for @selectPositionFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce Takım sekmesinden bir pozisyon seçin'**
  String get selectPositionFirst;

  /// No description provided for @userInfoFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bilgisi alınamadı'**
  String get userInfoFailed;

  /// No description provided for @joinedSuccessfully.
  ///
  /// In tr, this message translates to:
  /// **'Buluşmaya başarıyla katıldınız!'**
  String get joinedSuccessfully;

  /// No description provided for @reminderLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma için giriş yapmalısınız.'**
  String get reminderLoginRequired;

  /// No description provided for @spotNotification.
  ///
  /// In tr, this message translates to:
  /// **'Kontenjan açıldığında bildirim alacaksınız!'**
  String get spotNotification;

  /// No description provided for @removedFromWaitlist.
  ///
  /// In tr, this message translates to:
  /// **'Bekleme listesinden çıkarıldınız'**
  String get removedFromWaitlist;

  /// No description provided for @organizer.
  ///
  /// In tr, this message translates to:
  /// **'Organizatör'**
  String get organizer;

  /// No description provided for @seeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get seeAll;

  /// No description provided for @leaveWaitlist.
  ///
  /// In tr, this message translates to:
  /// **'Bekleme Listesinden Çık'**
  String get leaveWaitlist;

  /// No description provided for @leaveWaitlistConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kontenjan açıldığında bildirim almak istemediğinizden emin misiniz?'**
  String get leaveWaitlistConfirm;

  /// No description provided for @leave.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get leave;

  /// No description provided for @formation.
  ///
  /// In tr, this message translates to:
  /// **'Kadro Düzeni'**
  String get formation;

  /// No description provided for @teamNotSetUp.
  ///
  /// In tr, this message translates to:
  /// **'Takım kadrosu henüz oluşturulmamış.'**
  String get teamNotSetUp;

  /// No description provided for @noRulesAdded.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinlik için kural eklenmemiş.'**
  String get noRulesAdded;

  /// No description provided for @viewProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Gör'**
  String get viewProfile;

  /// No description provided for @leaveEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikten Ayrıl'**
  String get leaveEvent;

  /// No description provided for @leaveEventConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinlikten ayrılmak istediğinizden emin misiniz?'**
  String get leaveEventConfirm;

  /// No description provided for @leaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıl'**
  String get leaveButton;

  /// No description provided for @leftEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikten ayrıldınız'**
  String get leftEvent;

  /// No description provided for @autoFillSoon.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik doldurma yakında eklenecek.'**
  String get autoFillSoon;

  /// No description provided for @meetupLocation.
  ///
  /// In tr, this message translates to:
  /// **'Buluşma Yeri'**
  String get meetupLocation;

  /// No description provided for @generalTab.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get generalTab;

  /// No description provided for @teamTab.
  ///
  /// In tr, this message translates to:
  /// **'Takım'**
  String get teamTab;

  /// No description provided for @rulesTab.
  ///
  /// In tr, this message translates to:
  /// **'Kurallar'**
  String get rulesTab;

  /// No description provided for @matchFormat.
  ///
  /// In tr, this message translates to:
  /// **'Maç Formatı'**
  String get matchFormat;

  /// No description provided for @formationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Formasyon'**
  String get formationLabel;

  /// No description provided for @noFormationInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinlikte formasyon bilgisi bulunmuyor.'**
  String get noFormationInfo;

  /// No description provided for @goToGroupChat.
  ///
  /// In tr, this message translates to:
  /// **'Grup Sohbetine Git'**
  String get goToGroupChat;

  /// No description provided for @rateParticipants.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcıları Değerlendir'**
  String get rateParticipants;

  /// No description provided for @eventCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkinlik tamamlandı'**
  String get eventCompleted;

  /// No description provided for @onWaitlist.
  ///
  /// In tr, this message translates to:
  /// **'Bekleme Listesinde'**
  String get onWaitlist;

  /// No description provided for @remindMe.
  ///
  /// In tr, this message translates to:
  /// **'Beni Hatırlat'**
  String get remindMe;

  /// No description provided for @joinNow.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Katıl'**
  String get joinNow;

  /// No description provided for @profileUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla güncellendi!'**
  String get profileUpdated;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @changePhotoHint.
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafını değiştirmek için tıklayın'**
  String get changePhotoHint;

  /// No description provided for @usernameInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adınızı girin'**
  String get usernameInputHint;

  /// No description provided for @aboutInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendinizden bahsedin...'**
  String get aboutInputHint;

  /// No description provided for @locationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get locationLabel;

  /// No description provided for @cityDistrict.
  ///
  /// In tr, this message translates to:
  /// **'Şehir, İlçe'**
  String get cityDistrict;

  /// No description provided for @levelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Spor seviyeniz'**
  String get levelSubtitle;

  /// No description provided for @playStyleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl oynamayı seversiniz?'**
  String get playStyleSubtitle;

  /// No description provided for @funOriented.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence Amaçlı'**
  String get funOriented;

  /// No description provided for @multipleSelect.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçebilirsiniz'**
  String get multipleSelect;

  /// No description provided for @saveChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikleri Kaydet'**
  String get saveChanges;

  /// No description provided for @myPastEvents.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Etkinliklerim'**
  String get myPastEvents;

  /// No description provided for @noPastEvents.
  ///
  /// In tr, this message translates to:
  /// **'Henüz geçmiş etkinliğiniz yok'**
  String get noPastEvents;

  /// No description provided for @startJoiningEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliklere katılmaya başlayın!'**
  String get startJoiningEvents;

  /// No description provided for @discoverEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikleri Keşfet'**
  String get discoverEvents;

  /// No description provided for @sortNewest.
  ///
  /// In tr, this message translates to:
  /// **'En Yeni'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In tr, this message translates to:
  /// **'En Eski'**
  String get sortOldest;

  /// No description provided for @sortNameAZ.
  ///
  /// In tr, this message translates to:
  /// **'İsim (A-Z)'**
  String get sortNameAZ;

  /// No description provided for @sportType.
  ///
  /// In tr, this message translates to:
  /// **'Spor Türü'**
  String get sportType;

  /// No description provided for @eventCount.
  ///
  /// In tr, this message translates to:
  /// **' etkinlik'**
  String get eventCount;

  /// No description provided for @timeoutError.
  ///
  /// In tr, this message translates to:
  /// **'Zaman aşımı — lütfen tekrar deneyin'**
  String get timeoutError;

  /// No description provided for @noSharedEventError.
  ///
  /// In tr, this message translates to:
  /// **'Ortak etkinliğiniz olmadan istek gönderemezsiniz'**
  String get noSharedEventError;

  /// No description provided for @requestSentTo.
  ///
  /// In tr, this message translates to:
  /// **'{name} adlı kullanıcıya istek gönderildi'**
  String requestSentTo(String name);

  /// No description provided for @requestFailed.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderilemedi: {error}'**
  String requestFailed(String error);

  /// No description provided for @sentTab.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilen'**
  String get sentTab;

  /// No description provided for @suggestionsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler yüklenemedi'**
  String get suggestionsLoadFailed;

  /// No description provided for @noSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Öneri bulunamadı'**
  String get noSuggestions;

  /// No description provided for @sendRequest.
  ///
  /// In tr, this message translates to:
  /// **'İstek Gönder'**
  String get sendRequest;

  /// No description provided for @results.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlar'**
  String get results;

  /// No description provided for @allEvents.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Etkinlikler'**
  String get allEvents;

  /// No description provided for @seenAllEvents.
  ///
  /// In tr, this message translates to:
  /// **'Tüm etkinlikleri gördün'**
  String get seenAllEvents;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @almostFull.
  ///
  /// In tr, this message translates to:
  /// **'Dolmak Üzere'**
  String get almostFull;

  /// No description provided for @popularity.
  ///
  /// In tr, this message translates to:
  /// **'Popülerlik'**
  String get popularity;

  /// No description provided for @locationPermissionForFilter.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe filtresini kullanmak için izin verin'**
  String get locationPermissionForFilter;

  /// No description provided for @free.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get free;

  /// No description provided for @openNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an açık'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an kapalı'**
  String get closedNow;

  /// No description provided for @showOnMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Göster'**
  String get showOnMap;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In tr, this message translates to:
  /// **'Google Maps\'te aç'**
  String get openInGoogleMaps;

  /// No description provided for @venueLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mekan detayları yüklenemedi'**
  String get venueLoadFailed;

  /// No description provided for @checkInternetRetry.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen internet bağlantınızı kontrol edip tekrar deneyin'**
  String get checkInternetRetry;

  /// No description provided for @selectSportType.
  ///
  /// In tr, this message translates to:
  /// **'Spor Türü Seçin'**
  String get selectSportType;

  /// No description provided for @selectRegion.
  ///
  /// In tr, this message translates to:
  /// **'Bölge Seçin'**
  String get selectRegion;

  /// No description provided for @venueRecommendations.
  ///
  /// In tr, this message translates to:
  /// **'Mekan Önerileri'**
  String get venueRecommendations;

  /// No description provided for @noResultsInRegion.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölgede sonuç bulunamadı'**
  String get noResultsInRegion;

  /// No description provided for @tryDifferentRegion.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir bölge veya spor türü deneyin'**
  String get tryDifferentRegion;

  /// No description provided for @locationPermissionForDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe bilgisi için konum izni gerekli'**
  String get locationPermissionForDistance;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni reddedildi. Lütfen manuel olarak konum girin.'**
  String get locationPermissionDenied;

  /// No description provided for @venueType.
  ///
  /// In tr, this message translates to:
  /// **'Mekan Türü'**
  String get venueType;

  /// No description provided for @indoor.
  ///
  /// In tr, this message translates to:
  /// **'İç Mekan'**
  String get indoor;

  /// No description provided for @currentlyOpen.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Açık'**
  String get currentlyOpen;

  /// No description provided for @noSearchHistory.
  ///
  /// In tr, this message translates to:
  /// **'Henüz arama geçmişi yok'**
  String get noSearchHistory;

  /// No description provided for @daysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün önce'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} hafta önce'**
  String weeksAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay önce'**
  String monthsAgo(int count);

  /// No description provided for @noReviewsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok'**
  String get noReviewsYet;

  /// No description provided for @workingHours.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Saatleri'**
  String get workingHours;

  /// No description provided for @noWorkingHoursInfo.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma saatleri bilgisi yok'**
  String get noWorkingHoursInfo;

  /// No description provided for @open.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get closed;

  /// No description provided for @locationPermissionForSort.
  ///
  /// In tr, this message translates to:
  /// **'Mesafeye göre sıralama için konum izni gerekli'**
  String get locationPermissionForSort;

  /// No description provided for @eventDone.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Tamamlandı'**
  String get eventDone;

  /// No description provided for @eventDuration.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Süresi'**
  String get eventDuration;

  /// No description provided for @livePhotosHere.
  ///
  /// In tr, this message translates to:
  /// **'Aktif etkinliklerden paylaşılan fotoğraflar burada görünecek'**
  String get livePhotosHere;

  /// No description provided for @photoUploadError.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklenirken bir hata oluştu'**
  String get photoUploadError;

  /// No description provided for @noPhotosYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok'**
  String get noPhotosYet;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @addPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get addPhoto;

  /// No description provided for @reliabilityScore.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilirlik Skoru'**
  String get reliabilityScore;

  /// No description provided for @noPartnersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz partner yok'**
  String get noPartnersYet;

  /// No description provided for @noEventDataYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik verisi yok'**
  String get noEventDataYet;

  /// No description provided for @statsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler yüklenemedi: {error}'**
  String statsLoadFailed(String error);

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @mostDone.
  ///
  /// In tr, this message translates to:
  /// **'En Çok Yapılan'**
  String get mostDone;

  /// No description provided for @noActiveChats.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktif sohbetiniz yok'**
  String get noActiveChats;

  /// No description provided for @noPastChats.
  ///
  /// In tr, this message translates to:
  /// **'Henüz geçmiş sohbetiniz yok'**
  String get noPastChats;

  /// No description provided for @pastChatsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan etkinliklerin sohbetleri burada görünecek'**
  String get pastChatsSubtitle;

  /// No description provided for @ratingsFailed.
  ///
  /// In tr, this message translates to:
  /// **'Puanlar yüklenemedi. Lütfen tekrar deneyin.'**
  String get ratingsFailed;

  /// No description provided for @noRatingsReceived.
  ///
  /// In tr, this message translates to:
  /// **'Henüz puan almadınız'**
  String get noRatingsReceived;

  /// No description provided for @noRatingsGiven.
  ///
  /// In tr, this message translates to:
  /// **'Henüz puan vermediniz'**
  String get noRatingsGiven;

  /// No description provided for @photoLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar yüklenemedi'**
  String get photoLoadFailed;

  /// No description provided for @selectFromGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Seç'**
  String get selectFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Kamera ile Çek'**
  String get takePhoto;

  /// No description provided for @photoDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf silinemedi. Lütfen tekrar deneyin.'**
  String get photoDeleteFailed;

  /// No description provided for @reliability.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilirlik'**
  String get reliability;

  /// No description provided for @noEventsAttended.
  ///
  /// In tr, this message translates to:
  /// **'Henüz katıldığı etkinlik yok'**
  String get noEventsAttended;

  /// No description provided for @selectEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Seç'**
  String get selectEvent;

  /// No description provided for @pendingReviews.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme Bekleyenler'**
  String get pendingReviews;

  /// No description provided for @allReviewsDone.
  ///
  /// In tr, this message translates to:
  /// **'Tüm değerlendirmeler tamamlandı!'**
  String get allReviewsDone;

  /// No description provided for @needSharedEvent.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcıyla birlikte geçmiş bir etkinliğe katılmanız gerekiyor'**
  String get needSharedEvent;

  /// No description provided for @partnersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Partnerler yüklenirken hata oluştu: {error}'**
  String partnersLoadError(String error);

  /// No description provided for @eventsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler yüklenemedi. Lütfen tekrar deneyin.'**
  String get eventsLoadFailed;

  /// No description provided for @noSportPartners.
  ///
  /// In tr, this message translates to:
  /// **'Henüz spor partnerin yok'**
  String get noSportPartners;

  /// No description provided for @mostMeetups.
  ///
  /// In tr, this message translates to:
  /// **'En çok meetup'**
  String get mostMeetups;

  /// No description provided for @selectRating.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir puan seçin'**
  String get selectRating;

  /// No description provided for @ratingSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme başarıyla gönderildi!'**
  String get ratingSubmitted;

  /// No description provided for @partnerRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'Partner isteği gönderildi!'**
  String get partnerRequestSent;

  /// No description provided for @ratingSubmitFailed.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme gönderilemedi. Lütfen tekrar deneyin.'**
  String get ratingSubmitFailed;

  /// No description provided for @submitRating.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeyi Gönder'**
  String get submitRating;

  /// No description provided for @ratingsSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'{count} değerlendirme başarıyla gönderildi'**
  String ratingsSubmitted(int count);

  /// No description provided for @submitRatings.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeleri Gönder'**
  String get submitRatings;

  /// No description provided for @rateAtLeastOne.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmek için en az bir kişiye puan verin'**
  String get rateAtLeastOne;

  /// No description provided for @photoShared.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf başarıyla paylaşıldı'**
  String get photoShared;

  /// No description provided for @openOnMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Aç'**
  String get openOnMap;

  /// No description provided for @startPoint.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Noktası'**
  String get startPoint;

  /// No description provided for @errorRetry.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.'**
  String get errorRetry;

  /// No description provided for @weekdayMon.
  ///
  /// In tr, this message translates to:
  /// **'Pt'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In tr, this message translates to:
  /// **'Sa'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In tr, this message translates to:
  /// **'Ça'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In tr, this message translates to:
  /// **'Pe'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In tr, this message translates to:
  /// **'Cu'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In tr, this message translates to:
  /// **'Ct'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In tr, this message translates to:
  /// **'Pz'**
  String get weekdaySun;

  /// No description provided for @mapStyleCityNightGoldName.
  ///
  /// In tr, this message translates to:
  /// **'Sıcak Vintage'**
  String get mapStyleCityNightGoldName;

  /// No description provided for @mapStyleEnhancedName.
  ///
  /// In tr, this message translates to:
  /// **'Sportif (Açık)'**
  String get mapStyleEnhancedName;

  /// No description provided for @mapStyleDarkName.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Mod'**
  String get mapStyleDarkName;

  /// No description provided for @mapStyleLightName.
  ///
  /// In tr, this message translates to:
  /// **'Klasik Açık'**
  String get mapStyleLightName;

  /// No description provided for @mapStyleMinimalName.
  ///
  /// In tr, this message translates to:
  /// **'Minimal'**
  String get mapStyleMinimalName;

  /// No description provided for @mapStyleCityNightGoldDesc.
  ///
  /// In tr, this message translates to:
  /// **'Krem zemin, terrakota yollar, ılık vintage his'**
  String get mapStyleCityNightGoldDesc;

  /// No description provided for @mapStyleEnhancedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil tonlarında sportif görünüm'**
  String get mapStyleEnhancedDesc;

  /// No description provided for @mapStyleDarkDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gece kullanımı için karanlık tema'**
  String get mapStyleDarkDesc;

  /// No description provided for @mapStyleLightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Klasik açık renkli harita'**
  String get mapStyleLightDesc;

  /// No description provided for @mapStyleMinimalDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sade ve temiz görünüm'**
  String get mapStyleMinimalDesc;

  /// No description provided for @details.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get details;

  /// No description provided for @eventTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Başlığı'**
  String get eventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Sabah Koşusu 5K'**
  String get eventTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık gerekli'**
  String get titleRequired;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik hakkında detay...'**
  String get eventDescriptionHint;

  /// No description provided for @rules.
  ///
  /// In tr, this message translates to:
  /// **'Kurallar'**
  String get rules;

  /// No description provided for @rulesHint.
  ///
  /// In tr, this message translates to:
  /// **'Orn: Sert mudahale yok, gec gelen yedek olur...'**
  String get rulesHint;

  /// No description provided for @rulesRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kurallar gerekli'**
  String get rulesRequired;

  /// No description provided for @participantLimit.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı Sınırı'**
  String get participantLimit;

  /// No description provided for @maxParticipants.
  ///
  /// In tr, this message translates to:
  /// **'Maks. Katılımcı'**
  String get maxParticipants;

  /// No description provided for @skillLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get skillLevel;

  /// No description provided for @publishEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Yayınla'**
  String get publishEvent;

  /// No description provided for @searchLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Konum veya mekan ara...'**
  String get searchLocationHint;

  /// No description provided for @participants.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar'**
  String get participants;

  /// No description provided for @teamA.
  ///
  /// In tr, this message translates to:
  /// **'Takım A'**
  String get teamA;

  /// No description provided for @teamB.
  ///
  /// In tr, this message translates to:
  /// **'Takım B'**
  String get teamB;

  /// No description provided for @reviewCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} değerlendirme'**
  String reviewCount(int count);

  /// No description provided for @closeButton.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get closeButton;

  /// No description provided for @setLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ayarla'**
  String get setLabel;

  /// No description provided for @generalSection.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get generalSection;

  /// No description provided for @notificationTypes.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Türleri'**
  String get notificationTypes;

  /// No description provided for @muteAllNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Bildirimleri Sessize Al'**
  String get muteAllNotifications;

  /// No description provided for @muteAllNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm uygulama bildirimlerini geçici olarak kapat'**
  String get muteAllNotificationsSubtitle;

  /// No description provided for @meetupReminders.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Hatırlatmaları'**
  String get meetupReminders;

  /// No description provided for @meetupRemindersSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik başlamadan önce bildirim al'**
  String get meetupRemindersSubtitle;

  /// No description provided for @meetupUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Güncellemeleri'**
  String get meetupUpdates;

  /// No description provided for @meetupUpdatesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik değişikliklerinden haberdar ol'**
  String get meetupUpdatesSubtitle;

  /// No description provided for @chatMessages.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet Mesajları'**
  String get chatMessages;

  /// No description provided for @chatMessagesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Biri mesaj gönderdiğinde bildirim al'**
  String get chatMessagesSubtitle;

  /// No description provided for @newParticipants.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Katılımcılar'**
  String get newParticipants;

  /// No description provided for @newParticipantsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliğine biri katıldığında bildirim al'**
  String get newParticipantsSubtitle;

  /// No description provided for @systemNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Bildirimleri'**
  String get systemNotifications;

  /// No description provided for @systemNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önemli uygulama ve hesap güncellemeleri'**
  String get systemNotificationsSubtitle;

  /// No description provided for @quietHours.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz Saatler'**
  String get quietHours;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen saatlerde bildirimleri sessize al'**
  String get quietHoursSubtitle;

  /// No description provided for @startLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get endLabel;

  /// No description provided for @clearQuietHours.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz saatleri temizle'**
  String get clearQuietHours;

  /// No description provided for @incomingRequestsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Gelen istekler yüklenemedi: {error}'**
  String incomingRequestsLoadError(String error);

  /// No description provided for @outgoingRequestsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Giden istekler yüklenemedi: {error}'**
  String outgoingRequestsLoadError(String error);

  /// No description provided for @partnerRequestAccepted.
  ///
  /// In tr, this message translates to:
  /// **'Partnerlik isteği kabul edildi'**
  String get partnerRequestAccepted;

  /// No description provided for @partnerRequestRejected.
  ///
  /// In tr, this message translates to:
  /// **'Partnerlik isteği reddedildi'**
  String get partnerRequestRejected;

  /// No description provided for @partnerRequestCanceled.
  ///
  /// In tr, this message translates to:
  /// **'Partnerlik isteği iptal edildi'**
  String get partnerRequestCanceled;

  /// No description provided for @incomingTab.
  ///
  /// In tr, this message translates to:
  /// **'Gelen'**
  String get incomingTab;

  /// No description provided for @discoverTab.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get discoverTab;

  /// No description provided for @incomingRequestsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Gelen istek yok'**
  String get incomingRequestsEmpty;

  /// No description provided for @outgoingRequestsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Giden istek yok'**
  String get outgoingRequestsEmpty;

  /// No description provided for @discoverPartnersHint.
  ///
  /// In tr, this message translates to:
  /// **'Benzer spor ilgilerine sahip kişileri keşfetmeyi dene'**
  String get discoverPartnersHint;

  /// No description provided for @unknownUser.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Kullanıcı'**
  String get unknownUser;

  /// No description provided for @sharedMeetupCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ortak etkinlik'**
  String sharedMeetupCount(int count);

  /// No description provided for @accept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @pendingResponse.
  ///
  /// In tr, this message translates to:
  /// **'Yanıt bekleniyor'**
  String get pendingResponse;

  /// No description provided for @cancelRequest.
  ///
  /// In tr, this message translates to:
  /// **'İsteği İptal Et'**
  String get cancelRequest;

  /// No description provided for @participatedMeetups.
  ///
  /// In tr, this message translates to:
  /// **'Katıldığım Etkinlikler'**
  String get participatedMeetups;

  /// No description provided for @totalEvents.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Etkinlik'**
  String get totalEvents;

  /// No description provided for @myRatings.
  ///
  /// In tr, this message translates to:
  /// **'Puanlarım'**
  String get myRatings;

  /// No description provided for @ratingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Puanlar'**
  String get ratingsTitle;

  /// No description provided for @receivedRatingsTab.
  ///
  /// In tr, this message translates to:
  /// **'Alınan'**
  String get receivedRatingsTab;

  /// No description provided for @givenRatingsTab.
  ///
  /// In tr, this message translates to:
  /// **'Verilen'**
  String get givenRatingsTab;

  /// No description provided for @givenRatingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimseye puan vermedin'**
  String get givenRatingsSubtitle;

  /// No description provided for @givenRatingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Verilen Puanlar'**
  String get givenRatingLabel;

  /// No description provided for @anonymousUser.
  ///
  /// In tr, this message translates to:
  /// **'Anonim'**
  String get anonymousUser;

  /// No description provided for @coverPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Kapak Fotoğrafı'**
  String get coverPhoto;

  /// No description provided for @noParticipantsFound.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcı bulunamadı'**
  String get noParticipantsFound;

  /// No description provided for @player.
  ///
  /// In tr, this message translates to:
  /// **'Oyuncu'**
  String get player;

  /// No description provided for @partnerSuggestionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Partner önerisi'**
  String get partnerSuggestionTitle;

  /// No description provided for @notNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get notNow;

  /// No description provided for @addPartner.
  ///
  /// In tr, this message translates to:
  /// **'Partner Ekle'**
  String get addPartner;

  /// No description provided for @partnerBadge.
  ///
  /// In tr, this message translates to:
  /// **'Partner'**
  String get partnerBadge;

  /// No description provided for @requestSentStatus.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderildi'**
  String get requestSentStatus;

  /// No description provided for @acceptRequest.
  ///
  /// In tr, this message translates to:
  /// **'İsteği Kabul Et'**
  String get acceptRequest;

  /// No description provided for @partnerRequiresSharedEvent.
  ///
  /// In tr, this message translates to:
  /// **'Partner olmak için ortak bir etkinlik gerekli'**
  String get partnerRequiresSharedEvent;

  /// No description provided for @lockedMessageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Kilitli'**
  String get lockedMessageTitle;

  /// No description provided for @lockedMessageDescription.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj göndermek için etkinliğe katılmalısın.'**
  String get lockedMessageDescription;

  /// No description provided for @okButton.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get okButton;

  /// No description provided for @aboutAppDescription.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ve özellikleri hakkında bilgi al'**
  String get aboutAppDescription;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In tr, this message translates to:
  /// **'Farklı filtreler deneyin'**
  String get tryDifferentFilters;

  /// No description provided for @clearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri Temizle'**
  String get clearFilters;

  /// No description provided for @followersTab.
  ///
  /// In tr, this message translates to:
  /// **'Takipçiler'**
  String get followersTab;

  /// No description provided for @followingTab.
  ///
  /// In tr, this message translates to:
  /// **'Takip Edilenler'**
  String get followingTab;

  /// No description provided for @noFollowersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz takipçi yok'**
  String get noFollowersYet;

  /// No description provided for @noFollowingYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimseyi takip etmiyorsun'**
  String get noFollowingYet;

  /// No description provided for @sportPartnersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Spor Partnerleri'**
  String get sportPartnersTitle;

  /// No description provided for @findPartnersByJoiningEvents.
  ///
  /// In tr, this message translates to:
  /// **'Spor partneri bulmak için etkinliklere katıl'**
  String get findPartnersByJoiningEvents;

  /// No description provided for @searchByName.
  ///
  /// In tr, this message translates to:
  /// **'İsme göre ara'**
  String get searchByName;

  /// No description provided for @partnerCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} partner'**
  String partnerCount(int count);

  /// No description provided for @noParticipantsToRate.
  ///
  /// In tr, this message translates to:
  /// **'Puanlanacak katılımcı yok'**
  String get noParticipantsToRate;

  /// No description provided for @participantCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} katılımcı'**
  String participantCount(int count);

  /// No description provided for @commentMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'Yorum en fazla 500 karakter olabilir'**
  String get commentMaxLength;

  /// No description provided for @alreadyRatedUser.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcıyı bu etkinlik için zaten puanladın'**
  String get alreadyRatedUser;

  /// No description provided for @rateUserTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıyı Puanla'**
  String get rateUserTitle;

  /// No description provided for @eventLabel.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get eventLabel;

  /// No description provided for @yourRating.
  ///
  /// In tr, this message translates to:
  /// **'Puanın'**
  String get yourRating;

  /// No description provided for @commentOptional.
  ///
  /// In tr, this message translates to:
  /// **'Yorum (İsteğe bağlı)'**
  String get commentOptional;

  /// No description provided for @noRateableEvents.
  ///
  /// In tr, this message translates to:
  /// **'Puanlanabilir etkinlik bulunamadı'**
  String get noRateableEvents;

  /// No description provided for @noPendingReviews.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen değerlendirme yok'**
  String get noPendingReviews;

  /// No description provided for @participantsToRateCount.
  ///
  /// In tr, this message translates to:
  /// **'Puanlanacak {count} katılımcı'**
  String participantsToRateCount(int count);

  /// No description provided for @rateButton.
  ///
  /// In tr, this message translates to:
  /// **'Puanla'**
  String get rateButton;

  /// No description provided for @untitledEvent.
  ///
  /// In tr, this message translates to:
  /// **'Başlıksız etkinlik'**
  String get untitledEvent;

  /// No description provided for @monthlyAverage.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Ort.'**
  String get monthlyAverage;

  /// No description provided for @partnersShort.
  ///
  /// In tr, this message translates to:
  /// **'Partner'**
  String get partnersShort;

  /// No description provided for @currentLocationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut konum alınamıyor'**
  String get currentLocationUnavailable;

  /// No description provided for @selectPositionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pozisyon Seç'**
  String get selectPositionTitle;

  /// No description provided for @noPositionInfo.
  ///
  /// In tr, this message translates to:
  /// **'Pozisyon bilgisi yok'**
  String get noPositionInfo;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı Sil'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğrafı silmek istediğine emin misin?'**
  String get deletePhotoConfirm;

  /// No description provided for @mapLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Harita yüklenemedi'**
  String get mapLoadFailed;

  /// No description provided for @locationCoordinatesMissing.
  ///
  /// In tr, this message translates to:
  /// **'Konum koordinatları eksik'**
  String get locationCoordinatesMissing;

  /// No description provided for @routeCalculating.
  ///
  /// In tr, this message translates to:
  /// **'Rota hesaplanıyor...'**
  String get routeCalculating;

  /// No description provided for @waypointLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ara nokta {index}'**
  String waypointLabel(int index);

  /// No description provided for @nearbyMeetups.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Etkinlikler'**
  String get nearbyMeetups;

  /// No description provided for @filterLabel.
  ///
  /// In tr, this message translates to:
  /// **'Filtre'**
  String get filterLabel;

  /// No description provided for @clearButton.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearButton;

  /// No description provided for @venueNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Mekan bulunamadı'**
  String get venueNotFound;

  /// No description provided for @writeReviewTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme yaz'**
  String get writeReviewTooltip;

  /// No description provided for @writeReviewButton.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendir'**
  String get writeReviewButton;

  /// No description provided for @searchEventLocationSportHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik, konum veya spor ara...'**
  String get searchEventLocationSportHint;

  /// No description provided for @currentLocation.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Konum'**
  String get currentLocation;

  /// No description provided for @gettingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor...'**
  String get gettingLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Konumumu Kullan'**
  String get useCurrentLocation;

  /// No description provided for @searchLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum ara...'**
  String get searchLocation;

  /// No description provided for @shareYourExperienceHint.
  ///
  /// In tr, this message translates to:
  /// **'Deneyimini paylaş...'**
  String get shareYourExperienceHint;

  /// No description provided for @alreadyReviewed.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirildi'**
  String get alreadyReviewed;

  /// No description provided for @chatListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get chatListTitle;

  /// No description provided for @chatListSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik ve eslesme sohbetleri'**
  String get chatListSubtitle;

  /// No description provided for @swipeInviteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydir ve Davet Et'**
  String get swipeInviteTitle;

  /// No description provided for @swipeInviteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Saga kaydir, premium olarak spor daveti gonder.'**
  String get swipeInviteSubtitle;

  /// No description provided for @loginToUseSwipeInvites.
  ///
  /// In tr, this message translates to:
  /// **'Kaydirarak davet sistemini kullanmak icin giris yapin.'**
  String get loginToUseSwipeInvites;

  /// No description provided for @premiumActive.
  ///
  /// In tr, this message translates to:
  /// **'Premium Acik'**
  String get premiumActive;

  /// No description provided for @premiumLocked.
  ///
  /// In tr, this message translates to:
  /// **'Premium Kilitli'**
  String get premiumLocked;

  /// No description provided for @swipePremiumRequired.
  ///
  /// In tr, this message translates to:
  /// **'Saga kaydirip davet gondermek icin premium gerekli.'**
  String get swipePremiumRequired;

  /// No description provided for @swipeMatchCreated.
  ///
  /// In tr, this message translates to:
  /// **'Eslesme oldu. Sohbet baslatabilirsin.'**
  String get swipeMatchCreated;

  /// No description provided for @swipeInviteSent.
  ///
  /// In tr, this message translates to:
  /// **'Davet gonderildi.'**
  String get swipeInviteSent;

  /// No description provided for @swipeInviteAccepted.
  ///
  /// In tr, this message translates to:
  /// **'Davet kabul edildi.'**
  String get swipeInviteAccepted;

  /// No description provided for @swipeInviteRejected.
  ///
  /// In tr, this message translates to:
  /// **'Davet reddedildi.'**
  String get swipeInviteRejected;

  /// No description provided for @noSwipeCandidates.
  ///
  /// In tr, this message translates to:
  /// **'Simdilik gosterilecek aday yok.'**
  String get noSwipeCandidates;

  /// No description provided for @locationUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Konum bilgisi yok'**
  String get locationUnknown;

  /// No description provided for @noBioText.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanici henuz hakkinda bilgisi eklememis.'**
  String get noBioText;

  /// No description provided for @commonSportsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ortak spor'**
  String commonSportsCount(int count);

  /// No description provided for @swipePass.
  ///
  /// In tr, this message translates to:
  /// **'Gec'**
  String get swipePass;

  /// No description provided for @swipeInvite.
  ///
  /// In tr, this message translates to:
  /// **'Davet Et'**
  String get swipeInvite;

  /// No description provided for @swipePremiumOnly.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get swipePremiumOnly;

  /// No description provided for @swipeTabDiscover.
  ///
  /// In tr, this message translates to:
  /// **'Kesfet'**
  String get swipeTabDiscover;

  /// No description provided for @swipeTabIncoming.
  ///
  /// In tr, this message translates to:
  /// **'Gelen'**
  String get swipeTabIncoming;

  /// No description provided for @swipeTabMatches.
  ///
  /// In tr, this message translates to:
  /// **'Eslesmeler'**
  String get swipeTabMatches;

  /// No description provided for @incomingInvitesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelen Davetler'**
  String get incomingInvitesTitle;

  /// No description provided for @noIncomingInvites.
  ///
  /// In tr, this message translates to:
  /// **'Gelen davet yok.'**
  String get noIncomingInvites;

  /// No description provided for @rejectButton.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get rejectButton;

  /// No description provided for @acceptButton.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get acceptButton;

  /// No description provided for @matchesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eslesmeler'**
  String get matchesTitle;

  /// No description provided for @noMatchesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henuz eslesme yok.'**
  String get noMatchesYet;

  /// No description provided for @startChatButton.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet Baslat'**
  String get startChatButton;
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
