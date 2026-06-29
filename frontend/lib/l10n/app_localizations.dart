import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BuddBull'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your squad. Play your game.'**
  String get appTagline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your BuddBull account'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join BuddBull — it\'s free!'**
  String get registerSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Alex'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Rivera'**
  String get lastNameHint;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get usernameHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get confirmPasswordHint;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'I want to…'**
  String get roleLabel;

  /// No description provided for @rolePlayer.
  ///
  /// In en, this message translates to:
  /// **'Join games as a Player'**
  String get rolePlayer;

  /// No description provided for @roleOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organize & Captain games'**
  String get roleOrganizer;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get termsAgreement;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andText;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get forgotSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToLogin;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent! Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself…'**
  String get bioHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @neighborhoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get neighborhoodLabel;

  /// No description provided for @radiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Search radius (km)'**
  String get radiusLabel;

  /// No description provided for @sportsInterests.
  ///
  /// In en, this message translates to:
  /// **'Sports & Skill Levels'**
  String get sportsInterests;

  /// No description provided for @addSport.
  ///
  /// In en, this message translates to:
  /// **'+ Add sport'**
  String get addSport;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesPlayed;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakDays;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @amateur.
  ///
  /// In en, this message translates to:
  /// **'Amateur'**
  String get amateur;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsNoMatch;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters.'**
  String get usernameTooShort;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms of Service.'**
  String get acceptTerms;

  /// No description provided for @onboardingWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BuddBull! Let\'s get to know you better.'**
  String get onboardingWelcomeMessage;

  /// No description provided for @onboardingSportsSection.
  ///
  /// In en, this message translates to:
  /// **'What are your favourite sports? Tap to select — you can change this anytime.'**
  String get onboardingSportsSection;

  /// No description provided for @onboardingSkillPerSport.
  ///
  /// In en, this message translates to:
  /// **'Your level in each sport'**
  String get onboardingSkillPerSport;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use your area to match you with nearby games. Pick your city to continue.'**
  String get onboardingLocationSubtitle;

  /// No description provided for @onboardingLocationCityHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing your city…'**
  String get onboardingLocationCityHint;

  /// No description provided for @onboardingLocationNeighborhoodHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — neighbourhood or area'**
  String get onboardingLocationNeighborhoodHint;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is needed to find games near you. Enable it in settings or use city search.'**
  String get locationPermissionDenied;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo or pick a Buddy avatar. You can always update later.'**
  String get onboardingProfileSubtitle;

  /// No description provided for @onboardingUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload from device'**
  String get onboardingUploadPhoto;

  /// No description provided for @onboardingOrPickAvatar.
  ///
  /// In en, this message translates to:
  /// **'Or choose a starter avatar'**
  String get onboardingOrPickAvatar;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingFinish;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @unauthorised.
  ///
  /// In en, this message translates to:
  /// **'You are not authorised to do that.'**
  String get unauthorised;

  /// No description provided for @resourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get resourceNotFound;

  /// No description provided for @conflictError.
  ///
  /// In en, this message translates to:
  /// **'A conflict occurred.'**
  String get conflictError;

  /// No description provided for @badRequestError.
  ///
  /// In en, this message translates to:
  /// **'Invalid request.'**
  String get badRequestError;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get validationError;

  /// No description provided for @rateLimitedError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please slow down.'**
  String get rateLimitedError;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navChat;

  /// No description provided for @navPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get navPerformance;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @oops.
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get oops;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// No description provided for @searchGamesPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Search games, players…'**
  String get searchGamesPlayersHint;

  /// No description provided for @tooltipMyCalendar.
  ///
  /// In en, this message translates to:
  /// **'My calendar'**
  String get tooltipMyCalendar;

  /// No description provided for @fabAddGame.
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get fabAddGame;

  /// No description provided for @fabLogTraining.
  ///
  /// In en, this message translates to:
  /// **'Log Training'**
  String get fabLogTraining;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about activities'**
  String get pushNotificationsSubtitle;

  /// No description provided for @activityReminders.
  ///
  /// In en, this message translates to:
  /// **'Activity Reminders'**
  String get activityReminders;

  /// No description provided for @activityRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me before scheduled activities'**
  String get activityRemindersSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @remindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Activity reminders enabled'**
  String get remindersEnabled;

  /// No description provided for @remindersDisabled.
  ///
  /// In en, this message translates to:
  /// **'Activity reminders disabled'**
  String get remindersDisabled;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeEnabled;

  /// No description provided for @darkModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode disabled'**
  String get darkModeDisabled;

  /// No description provided for @tooltipAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get tooltipAdminDashboard;

  /// No description provided for @tooltipEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get tooltipEditProfile;

  /// No description provided for @tooltipSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get tooltipSignOut;

  /// No description provided for @mutualConnections.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No mutual connections} =1{1 mutual connection} other{{count} mutual connections}}'**
  String mutualConnections(int count);

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @sectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sectionLocation;

  /// No description provided for @locationRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'{radius} km radius'**
  String locationRadiusKm(int radius);

  /// No description provided for @sectionRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get sectionRecentActivity;

  /// No description provided for @dialogSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get dialogSignOutTitle;

  /// No description provided for @dialogSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get dialogSignOutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @winRatePercent.
  ///
  /// In en, this message translates to:
  /// **'Win Rate %'**
  String get winRatePercent;

  /// No description provided for @communityAverageRating.
  ///
  /// In en, this message translates to:
  /// **'Community average {rating} from {count} {ratingWord}'**
  String communityAverageRating(String rating, int count, String ratingWord);

  /// No description provided for @ratingSingular.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get ratingSingular;

  /// No description provided for @ratingsPlural.
  ///
  /// In en, this message translates to:
  /// **'ratings'**
  String get ratingsPlural;

  /// No description provided for @sectionSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sectionSports;

  /// No description provided for @sectionRatingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Ratings Summary'**
  String get sectionRatingsSummary;

  /// No description provided for @metricOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get metricOverall;

  /// No description provided for @metricReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get metricReliability;

  /// No description provided for @metricBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get metricBehavior;

  /// No description provided for @sectionUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Games'**
  String get sectionUpcomingGames;

  /// No description provided for @snackFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get snackFriendRequestSent;

  /// No description provided for @snackNowFriends.
  ///
  /// In en, this message translates to:
  /// **'You are now friends'**
  String get snackNowFriends;

  /// No description provided for @snackFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get snackFriendRequestDeclined;

  /// No description provided for @snackSignInToMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to send a message.'**
  String get snackSignInToMessage;

  /// No description provided for @snackCannotMessageSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot message yourself.'**
  String get snackCannotMessageSelf;

  /// No description provided for @buttonMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get buttonMessage;

  /// No description provided for @buttonRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get buttonRequestSent;

  /// No description provided for @buttonAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get buttonAccept;

  /// No description provided for @buttonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get buttonDecline;

  /// No description provided for @buttonAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get buttonAddFriend;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @activityDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String activityDurationMinutes(int minutes);

  /// No description provided for @greetingGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingGoodMorning;

  /// No description provided for @greetingGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingGoodAfternoon;

  /// No description provided for @greetingGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingGoodEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {firstName}!'**
  String greetingWithName(String greeting, String firstName);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}!'**
  String greetingNoName(String greeting);

  /// No description provided for @homeCollapsedTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'BuddBull'**
  String get homeCollapsedTitleFallback;

  /// No description provided for @tooltipNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tooltipNotifications;

  /// No description provided for @statGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get statGames;

  /// No description provided for @statRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @streakDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String streakDaysSuffix(int days);

  /// No description provided for @sectionMyUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'My Upcoming Games'**
  String get sectionMyUpcomingGames;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// No description provided for @sectionExploreNearYou.
  ///
  /// In en, this message translates to:
  /// **'Explore Near You'**
  String get sectionExploreNearYou;

  /// No description provided for @actionBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get actionBrowseAll;

  /// No description provided for @sectionQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get sectionQuickActions;

  /// No description provided for @quickActionFindGame.
  ///
  /// In en, this message translates to:
  /// **'Find a Game'**
  String get quickActionFindGame;

  /// No description provided for @quickActionLogSession.
  ///
  /// In en, this message translates to:
  /// **'Log Session'**
  String get quickActionLogSession;

  /// No description provided for @quickActionCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get quickActionCreateGame;

  /// No description provided for @emptyNoRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'No recent sessions'**
  String get emptyNoRecentSessions;

  /// No description provided for @actionLogSession.
  ///
  /// In en, this message translates to:
  /// **'Log a session'**
  String get actionLogSession;

  /// No description provided for @emptyNoUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'No upcoming games'**
  String get emptyNoUpcomingGames;

  /// No description provided for @actionBrowseGames.
  ///
  /// In en, this message translates to:
  /// **'Browse games'**
  String get actionBrowseGames;

  /// No description provided for @emptyCouldntLoadNearbyGames.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby games'**
  String get emptyCouldntLoadNearbyGames;

  /// No description provided for @emptyNothingNearby.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby right now'**
  String get emptyNothingNearby;

  /// No description provided for @tooltipCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create game'**
  String get tooltipCreateGame;

  /// No description provided for @searchGamesHint.
  ///
  /// In en, this message translates to:
  /// **'Search games, sports, locations…'**
  String get searchGamesHint;

  /// No description provided for @tooltipFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get tooltipFilter;

  /// No description provided for @sportFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sportFilterAll;

  /// No description provided for @sportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get sportFootball;

  /// No description provided for @sportBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get sportBasketball;

  /// No description provided for @sportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTennis;

  /// No description provided for @sportRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get sportRunning;

  /// No description provided for @sportSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get sportSwimming;

  /// No description provided for @sportCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get sportCycling;

  /// No description provided for @sportVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get sportVolleyball;

  /// No description provided for @sportCricket.
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get sportCricket;

  /// No description provided for @filtersActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter active} other{{count} filters active}}'**
  String filtersActive(int count);

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// No description provided for @emptyNoGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get emptyNoGamesFound;

  /// No description provided for @emptyTryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or create a new game.'**
  String get emptyTryAdjustingFilters;

  /// No description provided for @buttonCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get buttonCreateGame;

  /// No description provided for @filterGames.
  ///
  /// In en, this message translates to:
  /// **'Filter Games'**
  String get filterGames;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMe;

  /// No description provided for @requiredSkillLevel.
  ///
  /// In en, this message translates to:
  /// **'Required skill level'**
  String get requiredSkillLevel;

  /// No description provided for @createGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get createGameTitle;

  /// No description provided for @gameTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Game title *'**
  String get gameTitleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time *'**
  String get dateAndTime;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'Duration: {hours}h {minutes}min'**
  String durationHours(int hours, int minutes);

  /// No description provided for @durationMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes}min'**
  String durationMinutesOnly(int minutes);

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get locationRequired;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get addressLabel;

  /// No description provided for @venueNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get venueNameLabel;

  /// No description provided for @maxPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Max players: {count}'**
  String maxPlayersLabel(int count);

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @gameCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game created! 🎉'**
  String get gameCreatedSuccess;

  /// No description provided for @editGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get editGameTitle;

  /// No description provided for @gameUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game updated!'**
  String get gameUpdatedSuccess;

  /// No description provided for @myCalendar.
  ///
  /// In en, this message translates to:
  /// **'My Calendar'**
  String get myCalendar;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noGamesOnDay.
  ///
  /// In en, this message translates to:
  /// **'No games on this day'**
  String get noGamesOnDay;

  /// No description provided for @joinRequestDeclinedSnack.
  ///
  /// In en, this message translates to:
  /// **'Your request to join was declined. You can try again below.'**
  String get joinRequestDeclinedSnack;

  /// No description provided for @infoLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get infoLabelDate;

  /// No description provided for @infoLabelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get infoLabelTime;

  /// No description provided for @infoLabelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get infoLabelDuration;

  /// No description provided for @sectionAboutThisGame.
  ///
  /// In en, this message translates to:
  /// **'About this game'**
  String get sectionAboutThisGame;

  /// No description provided for @sectionOrganiser.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get sectionOrganiser;

  /// No description provided for @sectionPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get sectionPlayers;

  /// No description provided for @sectionMatchResult.
  ///
  /// In en, this message translates to:
  /// **'Match Result'**
  String get sectionMatchResult;

  /// No description provided for @sectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get sectionTags;

  /// No description provided for @mapPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get mapPreviewUnavailable;

  /// No description provided for @playerListApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get playerListApproved;

  /// No description provided for @playerListPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get playerListPendingRequests;

  /// No description provided for @playerYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'(You)'**
  String get playerYouSuffix;

  /// No description provided for @buttonRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get buttonRate;

  /// No description provided for @tooltipApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get tooltipApprove;

  /// No description provided for @tooltipKick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get tooltipKick;

  /// No description provided for @ratePromptBanner.
  ///
  /// In en, this message translates to:
  /// **'Rate participants below to share how the game went.'**
  String get ratePromptBanner;

  /// No description provided for @matchResultScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String matchResultScore(String score);

  /// No description provided for @matchResultWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {winner}'**
  String matchResultWinner(String winner);

  /// No description provided for @gameStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gameStatusOpen;

  /// No description provided for @gameStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get gameStatusFull;

  /// No description provided for @gameStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get gameStatusLive;

  /// No description provided for @gameStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get gameStatusCompleted;

  /// No description provided for @gameStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get gameStatusCancelled;

  /// No description provided for @reportGame.
  ///
  /// In en, this message translates to:
  /// **'Report Game'**
  String get reportGame;

  /// No description provided for @buttonChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get buttonChat;

  /// No description provided for @buttonRateParticipants.
  ///
  /// In en, this message translates to:
  /// **'Rate Participants'**
  String get buttonRateParticipants;

  /// No description provided for @buttonLeaveGame.
  ///
  /// In en, this message translates to:
  /// **'Leave Game'**
  String get buttonLeaveGame;

  /// No description provided for @buttonGameCompleted.
  ///
  /// In en, this message translates to:
  /// **'Game Completed'**
  String get buttonGameCompleted;

  /// No description provided for @buttonManageOrganiser.
  ///
  /// In en, this message translates to:
  /// **'Manage (Organiser)'**
  String get buttonManageOrganiser;

  /// No description provided for @buttonGameIsFull.
  ///
  /// In en, this message translates to:
  /// **'Game is Full'**
  String get buttonGameIsFull;

  /// No description provided for @buttonRequestToJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get buttonRequestToJoin;

  /// No description provided for @buttonJoinGame.
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get buttonJoinGame;

  /// No description provided for @inviteBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to this game'**
  String get inviteBannerTitle;

  /// No description provided for @buttonAcceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get buttonAcceptInvitation;

  /// No description provided for @pendingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending approval'**
  String get pendingApprovalMessage;

  /// No description provided for @buttonWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get buttonWithdraw;

  /// No description provided for @inviteFriendsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriendsSheetTitle;

  /// No description provided for @inviteFriendsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Add friends from their profile to invite them to games.'**
  String get inviteFriendsEmptyState;

  /// No description provided for @buttonInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get buttonInvited;

  /// No description provided for @snackInvitedFriend.
  ///
  /// In en, this message translates to:
  /// **'Invited {friendName}'**
  String snackInvitedFriend(String friendName);

  /// No description provided for @snackRevokedInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoked invite for {friendName}'**
  String snackRevokedInvite(String friendName);

  /// No description provided for @manageInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get manageInviteFriends;

  /// No description provided for @manageInviteFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an invite to your approved friends'**
  String get manageInviteFriendsSubtitle;

  /// No description provided for @manageEditGame.
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get manageEditGame;

  /// No description provided for @manageViewSummaryRatePlayers.
  ///
  /// In en, this message translates to:
  /// **'View Summary / Rate Players'**
  String get manageViewSummaryRatePlayers;

  /// No description provided for @manageViewSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Game is finished — open the rating flow for participants.'**
  String get manageViewSummarySubtitle;

  /// No description provided for @manageCompleteGame.
  ///
  /// In en, this message translates to:
  /// **'Complete Game'**
  String get manageCompleteGame;

  /// No description provided for @manageCompleteGameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark the game as finished and open ratings for participants.'**
  String get manageCompleteGameSubtitle;

  /// No description provided for @manageGameAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Game already cancelled'**
  String get manageGameAlreadyCancelled;

  /// No description provided for @manageCancelGame.
  ///
  /// In en, this message translates to:
  /// **'Cancel Game'**
  String get manageCancelGame;

  /// No description provided for @snackGameCancelled.
  ///
  /// In en, this message translates to:
  /// **'Game cancelled.'**
  String get snackGameCancelled;

  /// No description provided for @dialogCancelGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel game?'**
  String get dialogCancelGameTitle;

  /// No description provided for @dialogCancelGameBody.
  ///
  /// In en, this message translates to:
  /// **'This will mark the game as cancelled for all players.'**
  String get dialogCancelGameBody;

  /// No description provided for @dialogYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get dialogYesCancel;

  /// No description provided for @dialogCompleteGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete game?'**
  String get dialogCompleteGameTitle;

  /// No description provided for @dialogCompleteGameBody.
  ///
  /// In en, this message translates to:
  /// **'This marks the game as finished, updates player stats, and unlocks rating for all approved players. This action cannot be undone.'**
  String get dialogCompleteGameBody;

  /// No description provided for @dialogNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get dialogNotYet;

  /// No description provided for @dialogMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get dialogMarkCompleted;

  /// No description provided for @snackCouldNotLoadPendingRatings.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending ratings. Pull to refresh and try again.'**
  String get snackCouldNotLoadPendingRatings;

  /// No description provided for @fallbackPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get fallbackPlayerName;

  /// No description provided for @snackEveryoneRated.
  ///
  /// In en, this message translates to:
  /// **'Everyone in this game has been rated.'**
  String get snackEveryoneRated;

  /// No description provided for @rateParticipantPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate a participant'**
  String get rateParticipantPickerTitle;

  /// No description provided for @dontRateThisGame.
  ///
  /// In en, this message translates to:
  /// **'Don\'t rate this game'**
  String get dontRateThisGame;

  /// No description provided for @snackWontPromptToRate.
  ///
  /// In en, this message translates to:
  /// **'You will not be prompted to rate this game.'**
  String get snackWontPromptToRate;

  /// No description provided for @dialogCancelReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get dialogCancelReasonTitle;

  /// No description provided for @cancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weather, venue issue, not enough players…'**
  String get cancelReasonHint;

  /// No description provided for @dialogBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get dialogBack;

  /// No description provided for @dialogCancelGameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel game'**
  String get dialogCancelGameConfirm;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @tooltipNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get tooltipNewMessage;

  /// No description provided for @failedToLoadChats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get failedToLoadChats;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @notParticipantInChat.
  ///
  /// In en, this message translates to:
  /// **'You are no longer a participant in this chat.'**
  String get notParticipantInChat;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'• edited'**
  String get messageEdited;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @messageActionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get messageActionReply;

  /// No description provided for @messageActionCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get messageActionCopyText;

  /// No description provided for @messageActionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin message'**
  String get messageActionPin;

  /// No description provided for @messageActionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get messageActionUnpin;

  /// No description provided for @messageActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get messageActionDelete;

  /// No description provided for @logSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a Session'**
  String get logSessionTitle;

  /// No description provided for @sessionLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Session logged! 💪'**
  String get sessionLoggedSuccess;

  /// No description provided for @newPersonalBestTitle.
  ///
  /// In en, this message translates to:
  /// **'🏅 New Personal Best!'**
  String get newPersonalBestTitle;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @sessionType.
  ///
  /// In en, this message translates to:
  /// **'Session type *'**
  String get sessionType;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @howDidYouPerform.
  ///
  /// In en, this message translates to:
  /// **'How did you perform? {rating}/5'**
  String howDidYouPerform(int rating);

  /// No description provided for @howDidYouFeel.
  ///
  /// In en, this message translates to:
  /// **'How did you feel?'**
  String get howDidYouFeel;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session 💪'**
  String get saveSession;

  /// No description provided for @tooltipLogSession.
  ///
  /// In en, this message translates to:
  /// **'Log a session'**
  String get tooltipLogSession;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total sessions'**
  String get totalSessions;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get totalTime;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @personalBests.
  ///
  /// In en, this message translates to:
  /// **'Personal Bests'**
  String get personalBests;

  /// No description provided for @bySport.
  ///
  /// In en, this message translates to:
  /// **'By sport'**
  String get bySport;

  /// No description provided for @winRateTrend.
  ///
  /// In en, this message translates to:
  /// **'Win rate trend'**
  String get winRateTrend;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @snackAlreadyRatedPlayers.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated the players for this game.'**
  String get snackAlreadyRatedPlayers;

  /// No description provided for @snackCouldNotUpdateFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not update friend request'**
  String get snackCouldNotUpdateFriendRequest;

  /// No description provided for @snackJoinedGame.
  ///
  /// In en, this message translates to:
  /// **'You joined the game.'**
  String get snackJoinedGame;

  /// No description provided for @snackInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined.'**
  String get snackInviteDeclined;

  /// No description provided for @snackActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed.'**
  String get snackActionFailed;

  /// No description provided for @snackInvitationNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer valid.'**
  String get snackInvitationNoLongerValid;

  /// No description provided for @snackPlayerApproved.
  ///
  /// In en, this message translates to:
  /// **'Player approved.'**
  String get snackPlayerApproved;

  /// No description provided for @snackJoinRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Join request rejected.'**
  String get snackJoinRequestRejected;

  /// No description provided for @buttonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get buttonReject;

  /// No description provided for @emptyNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get emptyNotificationsTitle;

  /// No description provided for @emptyNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when something new happens.'**
  String get emptyNotificationsBody;

  /// No description provided for @relativeTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get relativeTimeNow;

  /// No description provided for @relativeTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String relativeTimeMinutes(int minutes);

  /// No description provided for @relativeTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String relativeTimeHours(int hours);

  /// No description provided for @relativeTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String relativeTimeDays(int days);

  /// No description provided for @relativeTimeWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w'**
  String relativeTimeWeeks(int weeks);

  /// No description provided for @confirmReport.
  ///
  /// In en, this message translates to:
  /// **'Confirm Report'**
  String get confirmReport;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @submitReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Report?'**
  String get submitReportTitle;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Admins will review it shortly.'**
  String get reportSubmitted;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetails;

  /// No description provided for @reportTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportTitleLabel;

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReasonLabel;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @searchSectionGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get searchSectionGames;

  /// No description provided for @searchSectionPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get searchSectionPlayers;

  /// No description provided for @ratePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Player'**
  String get ratePlayerTitle;

  /// No description provided for @ratingReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get ratingReliability;

  /// No description provided for @ratingReliabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Did they show up on time and follow through?'**
  String get ratingReliabilityHint;

  /// No description provided for @ratingSportsmanship.
  ///
  /// In en, this message translates to:
  /// **'Sportsmanship'**
  String get ratingSportsmanship;

  /// No description provided for @ratingSportsmanshipHint.
  ///
  /// In en, this message translates to:
  /// **'Were they fair, respectful, and fun to play with?'**
  String get ratingSportsmanshipHint;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment (optional)...'**
  String get ratingCommentHint;

  /// No description provided for @ratingSubmitAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Submit anonymously'**
  String get ratingSubmitAnonymously;

  /// No description provided for @ratingAnonymousHint.
  ///
  /// In en, this message translates to:
  /// **'Your name will not be shown to this player'**
  String get ratingAnonymousHint;

  /// No description provided for @buttonSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get buttonSubmitRating;

  /// No description provided for @snackRatingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted!'**
  String get snackRatingSubmitted;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @dialogUnfriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfriend?'**
  String get dialogUnfriendTitle;

  /// No description provided for @dialogUnfriendBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your friends? You can send a new request later.'**
  String dialogUnfriendBody(String name);

  /// No description provided for @buttonUnfriend.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get buttonUnfriend;

  /// No description provided for @snackRemovedFromFriends.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from friends'**
  String snackRemovedFromFriends(String name);

  /// No description provided for @emptyNoFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.\nVisit someone\'s profile and tap Add Friend.'**
  String get emptyNoFriendsYet;

  /// No description provided for @updateProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Picture'**
  String get updateProfilePicture;

  /// No description provided for @uploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from gallery'**
  String get uploadFromGallery;

  /// No description provided for @choosePresetAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose preset avatar'**
  String get choosePresetAvatar;

  /// No description provided for @changePhotoOrAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change photo or avatar'**
  String get changePhotoOrAvatar;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @dialogAddSportTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Sport'**
  String get dialogAddSportTitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @dialogDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get dialogDeleteAccountTitle;

  /// No description provided for @dialogDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all data.'**
  String get dialogDeleteAccountBody;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get adminSports;

  /// No description provided for @adminGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get adminGames;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @periodLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get periodLast7Days;

  /// No description provided for @periodLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get periodLast30Days;

  /// No description provided for @periodLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get periodLast90Days;

  /// No description provided for @sectionUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get sectionUsers;

  /// No description provided for @statTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get statTotalUsers;

  /// No description provided for @statActive30d.
  ///
  /// In en, this message translates to:
  /// **'Active (30d)'**
  String get statActive30d;

  /// No description provided for @statNewPeriod.
  ///
  /// In en, this message translates to:
  /// **'New (period)'**
  String get statNewPeriod;

  /// No description provided for @statBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get statBanned;

  /// No description provided for @statChurnRate.
  ///
  /// In en, this message translates to:
  /// **'Churn Rate'**
  String get statChurnRate;

  /// No description provided for @statChurnedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String statChurnedUsersSubtitle(int count);

  /// No description provided for @sectionRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get sectionRegistrations;

  /// No description provided for @sectionGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get sectionGames;

  /// No description provided for @statTotalGames.
  ///
  /// In en, this message translates to:
  /// **'Total Games'**
  String get statTotalGames;

  /// No description provided for @statActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statActive;

  /// No description provided for @statCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statCompleted;

  /// No description provided for @statCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statCancelled;

  /// No description provided for @statOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get statOngoing;

  /// No description provided for @statScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statScheduled;

  /// No description provided for @sectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sectionPerformance;

  /// No description provided for @statTotalLogs.
  ///
  /// In en, this message translates to:
  /// **'Total Logs'**
  String get statTotalLogs;

  /// No description provided for @sectionTopSports.
  ///
  /// In en, this message translates to:
  /// **'Top Sports'**
  String get sectionTopSports;

  /// No description provided for @globalBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Global Broadcast'**
  String get globalBroadcast;

  /// No description provided for @broadcastTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get broadcastTitleLabel;

  /// No description provided for @broadcastMessageBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Message body'**
  String get broadcastMessageBodyLabel;

  /// No description provided for @sendToAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Send to All Users'**
  String get sendToAllUsers;

  /// No description provided for @snackBroadcastSent.
  ///
  /// In en, this message translates to:
  /// **'Broadcast sent!'**
  String get snackBroadcastSent;

  /// No description provided for @snackBroadcastFailed.
  ///
  /// In en, this message translates to:
  /// **'Broadcast failed'**
  String get snackBroadcastFailed;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username, or email'**
  String get searchUsersHint;

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users: {error}'**
  String failedToLoadUsers(String error);

  /// No description provided for @failedToLoadGames.
  ///
  /// In en, this message translates to:
  /// **'Failed to load games: {error}'**
  String failedToLoadGames(String error);

  /// No description provided for @noGamesFoundAdmin.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get noGamesFoundAdmin;

  /// No description provided for @tooltipCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get tooltipCreateEvent;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get statusUsers;

  /// No description provided for @tooltipSortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by date'**
  String get tooltipSortByDate;

  /// No description provided for @failedToLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports: {error}'**
  String failedToLoadReports(String error);

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get noReportsFound;

  /// No description provided for @adminGamesPlayedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} games played'**
  String adminGamesPlayedCount(int count);

  /// No description provided for @adminStatusBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get adminStatusBanned;

  /// No description provided for @adminStatusRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get adminStatusRestricted;

  /// No description provided for @adminActionUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get adminActionUnban;

  /// No description provided for @adminActionBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get adminActionBan;

  /// No description provided for @adminActionUnrestrict.
  ///
  /// In en, this message translates to:
  /// **'Unrestrict'**
  String get adminActionUnrestrict;

  /// No description provided for @adminActionRestrict.
  ///
  /// In en, this message translates to:
  /// **'Restrict'**
  String get adminActionRestrict;

  /// No description provided for @adminActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminActionDelete;

  /// No description provided for @dialogDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get dialogDeleteUserTitle;

  /// No description provided for @dialogDeleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get dialogDeleteUserBody;

  /// No description provided for @extraPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String extraPlayersCount(int count);

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @logsTab.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @sportRequired.
  ///
  /// In en, this message translates to:
  /// **'Sport *'**
  String get sportRequired;

  /// No description provided for @logTypeMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get logTypeMatch;

  /// No description provided for @logTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get logTypeTraining;

  /// No description provided for @logTypeFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get logTypeFitness;

  /// No description provided for @outcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get outcomeWin;

  /// No description provided for @outcomeLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get outcomeLoss;

  /// No description provided for @outcomeDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get outcomeDraw;

  /// No description provided for @outcomeWinBadge.
  ///
  /// In en, this message translates to:
  /// **'🏆 Win'**
  String get outcomeWinBadge;

  /// No description provided for @outcomeLossBadge.
  ///
  /// In en, this message translates to:
  /// **'❌ Loss'**
  String get outcomeLossBadge;

  /// No description provided for @outcomeDrawBadge.
  ///
  /// In en, this message translates to:
  /// **'🤝 Draw'**
  String get outcomeDrawBadge;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'great'**
  String get moodGreat;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get moodGood;

  /// No description provided for @moodOk.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get moodOk;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'tired'**
  String get moodTired;

  /// No description provided for @moodInjured.
  ///
  /// In en, this message translates to:
  /// **'injured'**
  String get moodInjured;

  /// No description provided for @moodExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get moodExcellent;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @moodTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get moodTerrible;

  /// No description provided for @durationWithMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration: {minutes}min'**
  String durationWithMinutes(int minutes);

  /// No description provided for @sliderMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String sliderMinutesLabel(int minutes);

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'What went well? What to improve?'**
  String get notesHint;

  /// No description provided for @makeLogPublic.
  ///
  /// In en, this message translates to:
  /// **'Make this log public'**
  String get makeLogPublic;

  /// No description provided for @newPersonalBestBody.
  ///
  /// In en, this message translates to:
  /// **'You beat your previous record! Keep it up! 🎉'**
  String get newPersonalBestBody;

  /// No description provided for @newPersonalBestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new personal best!} other{{count} new personal bests!}}'**
  String newPersonalBestsCount(int count);

  /// No description provided for @sessionsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Sessions per week'**
  String get sessionsPerWeek;

  /// No description provided for @chartSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String chartSessionCount(int count);

  /// No description provided for @statsPreviewUnlock.
  ///
  /// In en, this message translates to:
  /// **'Your stats preview — log sessions to unlock'**
  String get statsPreviewUnlock;

  /// No description provided for @warmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming up'**
  String get warmingUp;

  /// No description provided for @activeStreak.
  ///
  /// In en, this message translates to:
  /// **'Active streak'**
  String get activeStreak;

  /// No description provided for @daySingular.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get daySingular;

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysPlural;

  /// No description provided for @personalBest.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get personalBest;

  /// No description provided for @logSessionStartStreak.
  ///
  /// In en, this message translates to:
  /// **'Log a session today to start your streak'**
  String get logSessionStartStreak;

  /// No description provided for @streakGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {goal}-day goal · Keep it going!'**
  String streakGoalProgress(int current, int goal);

  /// No description provided for @heatmapNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get heatmapNoActivity;

  /// No description provided for @heatmapSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String heatmapSessionCount(int count);

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @snackFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get snackFriendRequestAccepted;

  /// No description provided for @confirmReportBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report {targetName}? False reports may result in action against your account.'**
  String confirmReportBody(String targetName);

  /// No description provided for @reportTargetThisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get reportTargetThisUser;

  /// No description provided for @reportTargetThisGame.
  ///
  /// In en, this message translates to:
  /// **'this game'**
  String get reportTargetThisGame;

  /// No description provided for @submitReportBody.
  ///
  /// In en, this message translates to:
  /// **'Your report titled \"{title}\" will be sent to admins for review.'**
  String submitReportBody(String title);

  /// No description provided for @reportTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get reportTitleRequired;

  /// No description provided for @reportReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get reportReasonRequired;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @searchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search'**
  String get searchMinChars;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different sport, city, or player name'**
  String get searchNoResultsHint;

  /// No description provided for @searchDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your next game'**
  String get searchDiscoverTitle;

  /// No description provided for @searchDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search by sport, city, username, or player name'**
  String get searchDiscoverSubtitle;

  /// No description provided for @searchHintNearbyGames.
  ///
  /// In en, this message translates to:
  /// **'Nearby games'**
  String get searchHintNearbyGames;

  /// No description provided for @searchPartialGamesError.
  ///
  /// In en, this message translates to:
  /// **'Games: {error}'**
  String searchPartialGamesError(String error);

  /// No description provided for @searchPartialPlayersError.
  ///
  /// In en, this message translates to:
  /// **'Players: {error}'**
  String searchPartialPlayersError(String error);

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// No description provided for @adminNoUsersMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No users match \"{query}\".'**
  String adminNoUsersMatchSearch(String query);

  /// No description provided for @adminUserCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 user} other{{count} users}}'**
  String adminUserCount(int count);

  /// No description provided for @failedToLoadSports.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sports: {error}'**
  String failedToLoadSports(String error);

  /// No description provided for @adminNoSportsYet.
  ///
  /// In en, this message translates to:
  /// **'No sports yet'**
  String get adminNoSportsYet;

  /// No description provided for @adminSportActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminSportActive;

  /// No description provided for @adminSportInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminSportInactive;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminDeactivateSport.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminDeactivateSport;

  /// No description provided for @adminEditSport.
  ///
  /// In en, this message translates to:
  /// **'Edit Sport'**
  String get adminEditSport;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldNameLabel;

  /// No description provided for @fieldIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get fieldIconLabel;

  /// No description provided for @adminReporterLabel.
  ///
  /// In en, this message translates to:
  /// **'Reporter: @{username}'**
  String adminReporterLabel(String username);

  /// No description provided for @adminReportedUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported user: @{username}'**
  String adminReportedUserLabel(String username);

  /// No description provided for @adminReportedGameLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported game: {title}'**
  String adminReportedGameLabel(String title);

  /// No description provided for @fallbackUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get fallbackUnknown;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @adminNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin notes'**
  String get adminNotesLabel;

  /// No description provided for @adminSearchUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type to find a user and manage their account.'**
  String get adminSearchUserPrompt;

  /// No description provided for @adminNoUsersInDatabase.
  ///
  /// In en, this message translates to:
  /// **'No users in the database yet.'**
  String get adminNoUsersInDatabase;

  /// No description provided for @adminSearchMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String adminSearchMatchCount(int count);

  /// No description provided for @adminRecentUsersTotal.
  ///
  /// In en, this message translates to:
  /// **'Recent users ({total} total)'**
  String adminRecentUsersTotal(int total);

  /// No description provided for @adminViewAllResultsInUsers.
  ///
  /// In en, this message translates to:
  /// **'View all {total} results in Users'**
  String adminViewAllResultsInUsers(int total);

  /// No description provided for @adminOpenFullUsersList.
  ///
  /// In en, this message translates to:
  /// **'Open full Users list'**
  String get adminOpenFullUsersList;

  /// No description provided for @emptyNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get emptyNoConversations;

  /// No description provided for @emptyConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by tapping the edit icon above or opening a game and tapping Chat.'**
  String get emptyConversationsHint;

  /// No description provided for @chatTypingSingle.
  ///
  /// In en, this message translates to:
  /// **'{names} is typing...'**
  String chatTypingSingle(String names);

  /// No description provided for @chatTypingMultiple.
  ///
  /// In en, this message translates to:
  /// **'{names} are typing...'**
  String chatTypingMultiple(String names);

  /// No description provided for @replyingToName.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingToName(String name);

  /// No description provided for @chatMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String chatMembersCount(int count);

  /// No description provided for @pinnedMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessageLabel;

  /// No description provided for @emptyNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get emptyNoMessagesYet;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @gameTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunday 5-a-side'**
  String get gameTitleHint;

  /// No description provided for @gameTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get gameTitleRequired;

  /// No description provided for @gameDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional details, rules, what to bring…'**
  String get gameDescriptionHint;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing an address...'**
  String get addressHint;

  /// No description provided for @addressSelectFromSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Select a valid address from suggestions'**
  String get addressSelectFromSuggestions;

  /// No description provided for @addressVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify this address. Please choose another one.'**
  String get addressVerificationFailed;

  /// No description provided for @pleaseSelectValidAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid address from suggestions.'**
  String get pleaseSelectValidAddress;

  /// No description provided for @neighborhoodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shoreditch'**
  String get neighborhoodHint;

  /// No description provided for @venueNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hackney Marshes'**
  String get venueNameHint;

  /// No description provided for @cityRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get cityRequiredLabel;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. London'**
  String get cityHint;

  /// No description provided for @privateGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Game (Requires Approval)'**
  String get privateGameTitle;

  /// No description provided for @privateGameSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Hidden from public search. Every join request will require your approval.'**
  String get privateGameSubtitleOn;

  /// No description provided for @privateGameSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Public — anyone can find and join this game.'**
  String get privateGameSubtitleOff;

  /// No description provided for @anySkillLevel.
  ///
  /// In en, this message translates to:
  /// **'Any level'**
  String get anySkillLevel;

  /// No description provided for @createGameButton.
  ///
  /// In en, this message translates to:
  /// **'Create Game 🎮'**
  String get createGameButton;

  /// No description provided for @sectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionDetails;

  /// No description provided for @editTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get editTitleLabel;

  /// No description provided for @optionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @sectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get sectionSchedule;

  /// No description provided for @addressSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Selected address'**
  String get addressSelectedHint;

  /// No description provided for @cityRequiredError.
  ///
  /// In en, this message translates to:
  /// **'City is required.'**
  String get cityRequiredError;

  /// No description provided for @venueShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venueShortLabel;

  /// No description provided for @calendarNoGames.
  ///
  /// In en, this message translates to:
  /// **'No games'**
  String get calendarNoGames;

  /// No description provided for @calendarGamesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 game} other{{count} games}}'**
  String calendarGamesCount(int count);

  /// No description provided for @rosterLabel.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get rosterLabel;

  /// No description provided for @playersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{approved}/{max} players'**
  String playersCountLabel(int approved, int max);

  /// No description provided for @distanceMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String distanceMetersAway(int meters);

  /// No description provided for @distanceKmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceKmAway(String distance);

  /// No description provided for @pendingRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingRequestsCount(int count);

  /// No description provided for @placeCouldNotResolve.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve this place. Try another.'**
  String get placeCouldNotResolve;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
