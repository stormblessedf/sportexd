// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sporsal';

  @override
  String get findSportPartner => 'Find Your Sport Partner';

  @override
  String get login => 'Log In';

  @override
  String get loginToAccount => 'Log in to your account';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get chat => 'Chat';

  @override
  String get meetupNotFound => 'Meetup not found';

  @override
  String get chatInfoNotFound => 'Chat info not found';

  @override
  String get userNotFound => 'User not found';

  @override
  String get userInfoNotFound => 'User info not found';

  @override
  String get eventInfoNotFound => 'Event info not found';

  @override
  String get infoNotFound => 'Info not found';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get streamNotFound => 'Stream not found';

  @override
  String get settings => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get pastMeetups => 'Past Events';

  @override
  String get organizerCannotLeave => 'Organizer cannot leave their own event';

  @override
  String get notParticipant => 'You haven\'t joined this event';

  @override
  String get alreadyJoined => 'You\'ve already joined this event';

  @override
  String get eventFull => 'Event is full';

  @override
  String get invalidTeamSelection => 'Invalid team selection';

  @override
  String get invalidPositionSelection => 'Invalid position selection';

  @override
  String get positionTaken =>
      'This position is already taken. Please choose another.';

  @override
  String get selectPositionForFootball =>
      'You must select a position to join this football event';
}
