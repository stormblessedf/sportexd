// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Sporsal';

  @override
  String get findSportPartner => 'Trouvez votre partenaire sportif';

  @override
  String get login => 'Se connecter';

  @override
  String get loginToAccount => 'Connectez-vous à votre compte';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'exemple@email.com';

  @override
  String get emailRequired => 'L\'adresse e-mail est requise';

  @override
  String get emailInvalid => 'Entrez un e-mail valide';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get chat => 'Discussion';

  @override
  String get meetupNotFound => 'Rencontre introuvable';

  @override
  String get chatInfoNotFound => 'Infos de chat introuvables';

  @override
  String get userNotFound => 'Utilisateur introuvable';

  @override
  String get userInfoNotFound => 'Infos utilisateur introuvables';

  @override
  String get eventInfoNotFound => 'Infos sur l\'événement introuvables';

  @override
  String get infoNotFound => 'Infos introuvables';

  @override
  String get eventNotFound => 'Événement introuvable';

  @override
  String get streamNotFound => 'Flux introuvable';

  @override
  String get settings => 'Paramètres';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get pastMeetups => 'Événements passés';

  @override
  String get organizerCannotLeave =>
      'L\'organisateur ne peut pas quitter son propre événement';

  @override
  String get notParticipant => 'Vous n\'avez pas rejoint cet événement';

  @override
  String get alreadyJoined => 'Vous avez déjà rejoint cet événement';

  @override
  String get eventFull => 'Événement complet';

  @override
  String get invalidTeamSelection => 'Sélection d\'équipe invalide';

  @override
  String get invalidPositionSelection => 'Sélection de position invalide';

  @override
  String get positionTaken =>
      'Ce poste est déjà pris. Veuillez en choisir un autre.';

  @override
  String get selectPositionForFootball =>
      'Vous devez sélectionner un poste pour rejoindre cet événement de football';

  @override
  String get sectionAccount => 'Compte';

  @override
  String get editProfileSubtitle => 'Mettez à jour vos informations';

  @override
  String get sectionPrivacy => 'Confidentialité';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle => 'Sécurisez votre compte';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get privacySettingsSubtitle => 'Qui peut vous voir ?';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get notificationSettingsSubtitle =>
      'Quelles notifications souhaitez-vous recevoir ?';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get mapStyle => 'Style de carte';

  @override
  String get appLanguage => 'Langue de l\'app';

  @override
  String get appLanguageSubtitle => 'Sélectionnez la langue de l\'application.';

  @override
  String get sectionSupport => 'Support';

  @override
  String get helpSupport => 'Aide & Support';

  @override
  String get aboutApp => 'À propos';

  @override
  String get sectionAdmin => 'Administration';

  @override
  String get adminActions => 'Actions admin';

  @override
  String get adminActionsSubtitle => 'Outils de maintenance et de gestion';

  @override
  String get adminRatingsRecalculateSuccess =>
      'Succès ! Toutes les notes des utilisateurs ont été mises à jour.';

  @override
  String get adminPartnershipMigrationSuccess =>
      'Succès ! La migration des partenariats est terminée. Les paires d\'utilisateurs des événements passés ont été ajoutées comme partenaires.';

  @override
  String get adminRecalculateButton => 'Recalculer';

  @override
  String get adminDeleteImageLessButton =>
      'Supprimer les événements sans image';

  @override
  String get adminPartnershipMigrationButton =>
      'Lancer la migration des partenariats';

  @override
  String get adminMeetupRecalculateButton =>
      'Recalculer les compteurs d\'événements';

  @override
  String get adminReliabilityRecalculateButton =>
      'Mettre à jour les scores de fiabilité';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter';

  @override
  String get logoutConfirmContent =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get passwordChangeSoon =>
      'Changement de mot de passe bientôt disponible !';

  @override
  String get privacySettingsSoon =>
      'Paramètres de confidentialité bientôt disponibles !';

  @override
  String get helpSoon => 'Page d\'aide bientôt disponible !';

  @override
  String get navFeed => 'Fil';

  @override
  String get navChats => 'Chats';

  @override
  String get navCreate => 'Créer';

  @override
  String get navVenues => 'Lieux';

  @override
  String get navProfile => 'Profil';

  @override
  String get navPhoto => 'Photo';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpSubtitle => 'Ready to meet your sport buddies?';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get passwordMinChars => 'At least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailAlreadyInUse => 'This email is already in use.';

  @override
  String get weakPassword =>
      'Password is too weak. At least 6 characters required.';

  @override
  String get invalidEmail => 'Invalid email address.';

  @override
  String get continueButton => 'Continue';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get emailAccessibility => 'Email address input field';

  @override
  String get passwordAccessibility => 'Password input field';

  @override
  String get explore => 'Explore';

  @override
  String get following => 'Following';

  @override
  String get live => 'Live';

  @override
  String get exploreSubtitle => 'Discover activities near you';

  @override
  String get followingSubtitle => 'Activities from people you follow';

  @override
  String get liveSubtitle => 'Live shares from active events';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String errorOccurredWith(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get noEventsFollowing =>
      'People you follow haven\'t created any events yet';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get checkExploreTab => 'Check the Explore tab';

  @override
  String get createFirstEvent => 'Be the first to create an event!';

  @override
  String get loginToViewChats => 'Log in to view chats';

  @override
  String get loginToViewChatsSubtitle => 'Log in to access your event chats';

  @override
  String get filterChats => 'Filter Chats';

  @override
  String get bySportType => 'By Sport Type';

  @override
  String get sortByDate => 'Sort by Date';

  @override
  String get activeTab => 'Active';

  @override
  String get pastTab => 'Past';

  @override
  String get dmTab => 'DM';

  @override
  String get noDmYet => 'No direct messages yet';

  @override
  String get sendMessageToPartners => 'Send a message to your sport partners';

  @override
  String get userFallback => 'User';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get delete => 'Delete';

  @override
  String get reply => 'Reply';

  @override
  String get copy => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get edit => 'Edit';

  @override
  String get editFailed => 'Failed to edit message.';

  @override
  String get sendFailed => 'Failed to send message.';

  @override
  String get loginToJoinChat => 'You must log in to join the chat.';

  @override
  String get openToAll => 'Open to All';

  @override
  String get organizerOnly => 'Organizer Only';

  @override
  String get sendAnnouncement => 'Send Announcement';

  @override
  String get organizerModeActive => 'Organizer-only mode active';

  @override
  String get onlyOrganizerCanSend => 'Only the organizer can send messages';

  @override
  String get everyoneCanSend => 'Everyone can send messages';

  @override
  String get chatReadOnly => 'This event has ended. Chat is read-only.';

  @override
  String get noMessagesFirst => 'No messages yet. Be the first to send one!';

  @override
  String get cannotSendMessages => 'Cannot send messages to this chat';

  @override
  String get editing => 'Editing';

  @override
  String get editMessageHint => 'Edit message...';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get announcementHint => 'Write your announcement...';

  @override
  String get send => 'Send';

  @override
  String get edited => 'edited';

  @override
  String get messageDeleted => 'This message was deleted';

  @override
  String get profile => 'Profile';

  @override
  String get retryButton => 'Retry';

  @override
  String profileLoadFailed(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get sessionNotFound => 'User session not found';

  @override
  String get profilePicUpdated => 'Profile picture updated!';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get pastEventsTitle => 'My Past Events';

  @override
  String get partnershipAction => 'Partner Up';

  @override
  String get settingsMenu => 'Settings';

  @override
  String get earnedBadge => 'Earned';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get addProfilePhoto => 'Add Profile Photo';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameHint => 'Your username';

  @override
  String get minThreeChars => 'Must be at least 3 characters';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutHint => 'Tell us about yourself...';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get age => 'Age';

  @override
  String get height => 'Height (cm)';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get required => 'Required';

  @override
  String get invalid => 'Invalid';

  @override
  String get gender => 'Gender';

  @override
  String get selectGender => 'Select';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get location => 'Location';

  @override
  String get city => 'City';

  @override
  String get level => 'Level';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get playStyle => 'Play Style';

  @override
  String get casual => 'Casual';

  @override
  String get competitive => 'Competitive';

  @override
  String get interestedSports => 'Interested Sports';

  @override
  String get selectAtLeastOne => 'Select at least one';

  @override
  String get mustSelectOneSport => 'You must select at least one sport';

  @override
  String get sessionNotFoundLogin => 'Session not found. Please log in again.';

  @override
  String get profileCreated => 'Profile created successfully!';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get earlier => 'Earlier';

  @override
  String get markAllRead => 'Mark All as Read';

  @override
  String get allNotificationsRead => 'All notifications marked as read';

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get newNotificationsHere => 'New notifications will appear here';

  @override
  String get eventLoadError => 'Error loading event';

  @override
  String get justNow => 'Now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get sportRunning => 'Running';

  @override
  String get sportCycling => 'Cycling';

  @override
  String get sportFitness => 'Fitness';

  @override
  String get sportYoga => 'Yoga';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportVolleyball => 'Volleyball';

  @override
  String get sportSwimming => 'Swimming';

  @override
  String get sportHiking => 'Hiking';

  @override
  String get sportBoxing => 'Boxing';

  @override
  String get sportOther => 'Other';

  @override
  String get createEvent => 'Create Event';

  @override
  String get selectSport => 'Select Sport';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get startTime => 'START';

  @override
  String get endTime => 'END';

  @override
  String get description => 'Description';

  @override
  String get endTimeMustBeAfterStart => 'End time must be after start time';

  @override
  String get pleaseSelectLocation => 'Please select a location';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get eventCreated => 'Event created!';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get loginToJoin => 'You must log in to join.';

  @override
  String get selectPositionFirst => 'Select a position from the Team tab first';

  @override
  String get userInfoFailed => 'Failed to load user info';

  @override
  String get joinedSuccessfully => 'Successfully joined the meetup!';

  @override
  String get reminderLoginRequired => 'You must log in to set a reminder.';

  @override
  String get spotNotification => 'You\'ll be notified when a spot opens up!';

  @override
  String get removedFromWaitlist => 'Removed from waitlist';

  @override
  String get organizer => 'Organizer';

  @override
  String get seeAll => 'See All';

  @override
  String get leaveWaitlist => 'Leave Waitlist';

  @override
  String get leaveWaitlistConfirm =>
      'Are you sure you don\'t want to be notified when a spot opens?';

  @override
  String get leave => 'Leave';

  @override
  String get formation => 'Formation';

  @override
  String get teamNotSetUp => 'Team formation hasn\'t been set up yet.';

  @override
  String get noRulesAdded => 'No rules have been added for this event.';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get leaveEvent => 'Leave Event';

  @override
  String get leaveEventConfirm => 'Are you sure you want to leave this event?';

  @override
  String get leaveButton => 'Leave';

  @override
  String get leftEvent => 'You left the event';

  @override
  String get autoFillSoon => 'Auto-fill coming soon.';

  @override
  String get meetupLocation => 'Meeting Point';

  @override
  String get generalTab => 'General';

  @override
  String get teamTab => 'Team';

  @override
  String get rulesTab => 'Rules';

  @override
  String get matchFormat => 'Match Format';

  @override
  String get formationLabel => 'Formation';

  @override
  String get noFormationInfo => 'No formation info available for this event.';

  @override
  String get goToGroupChat => 'Go to Group Chat';

  @override
  String get rateParticipants => 'Rate Participants';

  @override
  String get eventCompleted => 'This event has been completed';

  @override
  String get onWaitlist => 'On Waitlist';

  @override
  String get remindMe => 'Remind Me';

  @override
  String get joinNow => 'Join Now';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get save => 'Save';

  @override
  String get changePhotoHint => 'Tap to change profile photo';

  @override
  String get usernameInputHint => 'Enter your username';

  @override
  String get aboutInputHint => 'Tell us about yourself...';

  @override
  String get locationLabel => 'Location';

  @override
  String get cityDistrict => 'City, District';

  @override
  String get levelSubtitle => 'Your sport level';

  @override
  String get playStyleSubtitle => 'How do you like to play?';

  @override
  String get funOriented => 'For Fun';

  @override
  String get multipleSelect => 'You can select multiple';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get myPastEvents => 'My Past Events';

  @override
  String get noPastEvents => 'No past events yet';

  @override
  String get startJoiningEvents => 'Start joining events!';

  @override
  String get discoverEvents => 'Discover Events';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortNameAZ => 'Name (A-Z)';

  @override
  String get sportType => 'Sport Type';

  @override
  String get eventCount => ' events';

  @override
  String get timeoutError => 'Délai dépassé, veuillez réessayer';

  @override
  String get noSharedEventError =>
      'You can\'t send a request without a shared event';

  @override
  String requestSentTo(String name) {
    return 'Request sent to $name';
  }

  @override
  String requestFailed(String error) {
    return 'Failed to send request: $error';
  }

  @override
  String get sentTab => 'Sent';

  @override
  String get suggestionsLoadFailed => 'Failed to load suggestions';

  @override
  String get noSuggestions => 'No suggestions found';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get results => 'Results';

  @override
  String get allEvents => 'All Events';

  @override
  String get seenAllEvents => 'You\'ve seen all events';

  @override
  String get noResults => 'No results found';

  @override
  String get all => 'All';

  @override
  String get almostFull => 'Almost Full';

  @override
  String get popularity => 'Popularity';

  @override
  String get locationPermissionForFilter =>
      'Allow location access to use distance filter';

  @override
  String get free => 'Free';

  @override
  String get openNow => 'Open now';

  @override
  String get closedNow => 'Closed now';

  @override
  String get showOnMap => 'Show on Map';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get venueLoadFailed => 'Failed to load venue details';

  @override
  String get checkInternetRetry =>
      'Please check your internet connection and try again';

  @override
  String get selectSportType => 'Select Sport Type';

  @override
  String get selectRegion => 'Select Region';

  @override
  String get venueRecommendations => 'Venue Recommendations';

  @override
  String get noResultsInRegion => 'No results in this region';

  @override
  String get tryDifferentRegion => 'Try a different region or sport type';

  @override
  String get locationPermissionForDistance =>
      'Location permission required for distance info';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Please enter location manually.';

  @override
  String get venueType => 'Venue Type';

  @override
  String get indoor => 'Indoor';

  @override
  String get currentlyOpen => 'Currently Open';

  @override
  String get noSearchHistory => 'No search history yet';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get noWorkingHoursInfo => 'No working hours info available';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get locationPermissionForSort =>
      'Location permission required for distance sorting';

  @override
  String get eventDone => 'Event Completed';

  @override
  String get eventDuration => 'Event Duration';

  @override
  String get livePhotosHere =>
      'Photos shared from active events will appear here';

  @override
  String get photoUploadError => 'Error uploading photo';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get loading => 'Loading...';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get reliabilityScore => 'Reliability Score';

  @override
  String get noPartnersYet => 'No partners yet';

  @override
  String get noEventDataYet => 'No event data yet';

  @override
  String statsLoadFailed(String error) {
    return 'Failed to load statistics: $error';
  }

  @override
  String get statistics => 'Statistics';

  @override
  String get mostDone => 'Most Done';

  @override
  String get noActiveChats => 'No active chats yet';

  @override
  String get noPastChats => 'No past chats yet';

  @override
  String get pastChatsSubtitle =>
      'Chats from completed events will appear here';

  @override
  String get ratingsFailed => 'Failed to load ratings. Please try again.';

  @override
  String get noRatingsReceived => 'No ratings received yet';

  @override
  String get noRatingsGiven => 'No ratings given yet';

  @override
  String get photoLoadFailed => 'Failed to load photos';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get photoDeleteFailed => 'Failed to delete photo. Please try again.';

  @override
  String get reliability => 'Reliability';

  @override
  String get noEventsAttended => 'No events attended yet';

  @override
  String get selectEvent => 'Select Event';

  @override
  String get pendingReviews => 'Pending Reviews';

  @override
  String get allReviewsDone => 'All reviews completed!';

  @override
  String get needSharedEvent =>
      'You need to have attended a past event with this user';

  @override
  String partnersLoadError(String error) {
    return 'Error loading partners: $error';
  }

  @override
  String get eventsLoadFailed => 'Failed to load events. Please try again.';

  @override
  String get noSportPartners => 'No sport partners yet';

  @override
  String get mostMeetups => 'Most meetups';

  @override
  String get selectRating => 'Please select a rating';

  @override
  String get ratingSubmitted => 'Rating submitted successfully!';

  @override
  String get partnerRequestSent => 'Partner request sent!';

  @override
  String get ratingSubmitFailed => 'Failed to submit rating. Please try again.';

  @override
  String get submitRating => 'Submit Rating';

  @override
  String ratingsSubmitted(int count) {
    return '$count ratings submitted successfully';
  }

  @override
  String get submitRatings => 'Submit Ratings';

  @override
  String get rateAtLeastOne => 'Rate at least one person to submit';

  @override
  String get photoShared => 'Photo shared successfully';

  @override
  String get openOnMap => 'Open on Map';

  @override
  String get startPoint => 'Start Point';

  @override
  String get errorRetry => 'An error occurred. Please try again later.';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get mapStyleCityNightGoldName => 'Vintage Chaud';

  @override
  String get mapStyleEnhancedName => 'Sportif (Clair)';

  @override
  String get mapStyleDarkName => 'Mode sombre';

  @override
  String get mapStyleLightName => 'Classique clair';

  @override
  String get mapStyleMinimalName => 'Minimal';

  @override
  String get mapStyleCityNightGoldDesc =>
      'Fond crème avec routes en terre cuite et eau bleue tamisée';

  @override
  String get mapStyleEnhancedDesc => 'Style sportif avec des tons verts';

  @override
  String get mapStyleDarkDesc => 'Thème sombre pour une utilisation nocturne';

  @override
  String get mapStyleLightDesc => 'Carte classique aux tons clairs';

  @override
  String get mapStyleMinimalDesc => 'Style épuré et simple';

  @override
  String get details => 'Details';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventTitleHint => 'Morning Run 5K';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get eventDescriptionHint => 'Details about the event...';

  @override
  String get rules => 'Rules';

  @override
  String get rulesHint => 'E.g.: No harsh tackles, latecomers are subs...';

  @override
  String get rulesRequired => 'Rules are required';

  @override
  String get participantLimit => 'Participant Limit';

  @override
  String get maxParticipants => 'Max. Participants';

  @override
  String get skillLevel => 'Skill Level';

  @override
  String get publishEvent => 'Publish Event';

  @override
  String get searchLocationHint => 'Search for a location or venue...';

  @override
  String get participants => 'Participants';

  @override
  String get teamA => 'Team A';

  @override
  String get teamB => 'Team B';

  @override
  String reviewCount(int count) {
    return '$count reviews';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get setLabel => 'Set';

  @override
  String get generalSection => 'General';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get muteAllNotifications => 'Mute All Notifications';

  @override
  String get muteAllNotificationsSubtitle =>
      'Temporarily disable all app notifications';

  @override
  String get meetupReminders => 'Meetup Reminders';

  @override
  String get meetupRemindersSubtitle => 'Get notified before your events start';

  @override
  String get meetupUpdates => 'Meetup Updates';

  @override
  String get meetupUpdatesSubtitle => 'Receive updates about meetup changes';

  @override
  String get chatMessages => 'Chat Messages';

  @override
  String get chatMessagesSubtitle =>
      'Get notified when someone sends a message';

  @override
  String get newParticipants => 'New Participants';

  @override
  String get newParticipantsSubtitle =>
      'Get notified when someone joins your meetup';

  @override
  String get systemNotifications => 'System Notifications';

  @override
  String get systemNotificationsSubtitle => 'Important app and account updates';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursSubtitle =>
      'Silence notifications during selected hours';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get clearQuietHours => 'Clear quiet hours';

  @override
  String incomingRequestsLoadError(String error) {
    return 'Failed to load incoming requests: $error';
  }

  @override
  String outgoingRequestsLoadError(String error) {
    return 'Failed to load outgoing requests: $error';
  }

  @override
  String get partnerRequestAccepted => 'Partnership request accepted';

  @override
  String get partnerRequestRejected => 'Partnership request rejected';

  @override
  String get partnerRequestCanceled => 'Partnership request canceled';

  @override
  String get incomingTab => 'Incoming';

  @override
  String get discoverTab => 'Discover';

  @override
  String get incomingRequestsEmpty => 'No incoming requests';

  @override
  String get outgoingRequestsEmpty => 'No outgoing requests';

  @override
  String get discoverPartnersHint =>
      'Try exploring people with similar sports interests';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String sharedMeetupCount(int count) {
    return '$count shared events';
  }

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get pendingResponse => 'Pending response';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get participatedMeetups => 'Participated Meetups';

  @override
  String get totalEvents => 'Total Events';

  @override
  String get myRatings => 'My Ratings';

  @override
  String get ratingsTitle => 'Ratings';

  @override
  String get receivedRatingsTab => 'Received';

  @override
  String get givenRatingsTab => 'Given';

  @override
  String get givenRatingsSubtitle => 'You haven\'t rated anyone yet';

  @override
  String get givenRatingLabel => 'Given Ratings';

  @override
  String get anonymousUser => 'Anonymous';

  @override
  String get coverPhoto => 'Cover Photo';

  @override
  String get noParticipantsFound => 'No participants found';

  @override
  String get player => 'Player';

  @override
  String get partnerSuggestionTitle => 'Suggested partner';

  @override
  String get notNow => 'Not now';

  @override
  String get addPartner => 'Add Partner';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get requestSentStatus => 'Request sent';

  @override
  String get acceptRequest => 'Accept Request';

  @override
  String get partnerRequiresSharedEvent =>
      'You need a shared event to become partners';

  @override
  String get lockedMessageTitle => 'Message Locked';

  @override
  String get lockedMessageDescription =>
      'You need to join the event to send messages.';

  @override
  String get okButton => 'OK';

  @override
  String get aboutAppDescription =>
      'Learn more about this app and its features';

  @override
  String get tryDifferentFilters => 'Try different filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get followersTab => 'Followers';

  @override
  String get followingTab => 'Following';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get noFollowingYet => 'Not following anyone yet';

  @override
  String get sportPartnersTitle => 'Sport Partners';

  @override
  String get findPartnersByJoiningEvents =>
      'Join events to find sport partners';

  @override
  String get searchByName => 'Search by name';

  @override
  String partnerCount(int count) {
    return '$count partners';
  }

  @override
  String get noParticipantsToRate => 'No participants to rate';

  @override
  String participantCount(int count) {
    return '$count participants';
  }

  @override
  String get commentMaxLength => 'Comment can be at most 500 characters';

  @override
  String get alreadyRatedUser => 'You already rated this user for this event';

  @override
  String get rateUserTitle => 'Rate User';

  @override
  String get eventLabel => 'Event';

  @override
  String get yourRating => 'Your Rating';

  @override
  String get commentOptional => 'Comment (Optional)';

  @override
  String get noRateableEvents => 'No rateable events found';

  @override
  String get noPendingReviews => 'No pending reviews';

  @override
  String participantsToRateCount(int count) {
    return '$count participants to rate';
  }

  @override
  String get rateButton => 'Rate';

  @override
  String get untitledEvent => 'Untitled event';

  @override
  String get monthlyAverage => 'Monthly Avg';

  @override
  String get partnersShort => 'Partners';

  @override
  String get currentLocationUnavailable => 'Current location is unavailable';

  @override
  String get selectPositionTitle => 'Select Position';

  @override
  String get noPositionInfo => 'No position info';

  @override
  String get deletePhotoTitle => 'Delete Photo';

  @override
  String get deletePhotoConfirm =>
      'Are you sure you want to delete this photo?';

  @override
  String get mapLoadFailed => 'Failed to load map';

  @override
  String get locationCoordinatesMissing => 'Location coordinates are missing';

  @override
  String get routeCalculating => 'Calculating route...';

  @override
  String waypointLabel(int index) {
    return 'Waypoint $index';
  }

  @override
  String get nearbyMeetups => 'Nearby Meetups';

  @override
  String get filterLabel => 'Filter';

  @override
  String get clearButton => 'Clear';

  @override
  String get venueNotFound => 'Venue not found';

  @override
  String get writeReviewTooltip => 'Write a review';

  @override
  String get writeReviewButton => 'Write Review';

  @override
  String get searchEventLocationSportHint =>
      'Search event, location or sport...';

  @override
  String get currentLocation => 'Position actuelle';

  @override
  String get gettingLocation => 'Récupération de la position...';

  @override
  String get useCurrentLocation => 'Utiliser ma position actuelle';

  @override
  String get searchLocation => 'Rechercher un lieu...';

  @override
  String get shareYourExperienceHint => 'Partagez votre expérience...';

  @override
  String get alreadyReviewed => 'Reviewed';

  @override
  String get chatListTitle => 'Discussions';

  @override
  String get chatListSubtitle => 'Discussions d\'evenements et de matchs';

  @override
  String get swipeInviteTitle => 'Glisser et Inviter';

  @override
  String get swipeInviteSubtitle =>
      'Glissez a droite pour envoyer une invitation sportive avec Premium.';

  @override
  String get loginToUseSwipeInvites =>
      'Connectez-vous pour utiliser les invitations par glissement.';

  @override
  String get premiumActive => 'Premium Actif';

  @override
  String get premiumLocked => 'Premium Verrouille';

  @override
  String get swipePremiumRequired =>
      'Premium est requis pour envoyer une invitation en glissant a droite.';

  @override
  String get swipeMatchCreated =>
      'C\'est un match. Vous pouvez demarrer la discussion.';

  @override
  String get swipeInviteSent => 'Invitation envoyee.';

  @override
  String get swipeInviteAccepted => 'Invitation acceptee.';

  @override
  String get swipeInviteRejected => 'Invitation refusee.';

  @override
  String get noSwipeCandidates => 'Aucun profil a afficher pour le moment.';

  @override
  String get locationUnknown => 'Position indisponible';

  @override
  String get noBioText => 'Cet utilisateur n\'a pas encore ajoute de bio.';

  @override
  String commonSportsCount(int count) {
    return '$count sports en commun';
  }

  @override
  String get swipePass => 'Passer';

  @override
  String get swipeInvite => 'Inviter';

  @override
  String get swipePremiumOnly => 'Premium';

  @override
  String get swipeTabDiscover => 'Kesfet';

  @override
  String get swipeTabIncoming => 'Gelen';

  @override
  String get swipeTabMatches => 'Eslesmeler';

  @override
  String get incomingInvitesTitle => 'Invitations recues';

  @override
  String get noIncomingInvites => 'Aucune invitation recue.';

  @override
  String get rejectButton => 'Refuser';

  @override
  String get acceptButton => 'Accepter';

  @override
  String get matchesTitle => 'Matchs';

  @override
  String get noMatchesYet => 'Aucun match pour le moment.';

  @override
  String get startChatButton => 'Demarrer le chat';
}
