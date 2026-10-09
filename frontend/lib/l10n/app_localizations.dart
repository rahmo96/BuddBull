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

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get languageDeviceDefault;

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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonOops.
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get commonOops;

  /// No description provided for @validationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationFieldRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationInvalidEmail;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPasswordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordsNoMatch;

  /// No description provided for @validationUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters.'**
  String get validationUsernameTooShort;

  /// No description provided for @validationAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms of Service.'**
  String get validationAcceptTerms;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your BuddBull account'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get authPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authLoginButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authSignUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpLink;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join BuddBull — it\'s free!'**
  String get authRegisterSubtitle;

  /// No description provided for @authFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authFirstNameLabel;

  /// No description provided for @authFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Alex'**
  String get authFirstNameHint;

  /// No description provided for @authLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authLastNameLabel;

  /// No description provided for @authLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Rivera'**
  String get authLastNameHint;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get authUsernameHint;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authNewPasswordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authTermsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authTermsAgreement;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authTermsAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInLink;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPasswordTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get authForgotSubtitle;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get authBackToLogin;

  /// No description provided for @authResetInfo.
  ///
  /// In en, this message translates to:
  /// **'The reset link expires in 10 minutes. Check your spam folder if you don\'t see the email.'**
  String get authResetInfo;

  /// No description provided for @authPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get authPasswordWeak;

  /// No description provided for @authPasswordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get authPasswordFair;

  /// No description provided for @authPasswordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get authPasswordGood;

  /// No description provided for @authPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get authPasswordStrong;

  /// No description provided for @skillBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get skillBeginner;

  /// No description provided for @skillAmateur.
  ///
  /// In en, this message translates to:
  /// **'Amateur'**
  String get skillAmateur;

  /// No description provided for @skillIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get skillIntermediate;

  /// No description provided for @skillAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get skillAdvanced;

  /// No description provided for @skillProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get skillProfessional;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileNeighborhoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get profileNeighborhoodLabel;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOf(int step, int total);

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

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get commonBrowseAll;

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

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}!'**
  String homeGreetingWithName(String greeting, String name);

  /// No description provided for @homeGreetingNoName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}!'**
  String homeGreetingNoName(String greeting);

  /// No description provided for @homeStatGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get homeStatGames;

  /// No description provided for @homeStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get homeStatRating;

  /// No description provided for @homeStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get homeStatStreak;

  /// No description provided for @homeStreakDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String homeStreakDaysShort(int count);

  /// No description provided for @homeMyUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'My Upcoming Games'**
  String get homeMyUpcomingGames;

  /// No description provided for @homeExploreNearYou.
  ///
  /// In en, this message translates to:
  /// **'Explore Near You'**
  String get homeExploreNearYou;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeFindGame.
  ///
  /// In en, this message translates to:
  /// **'Find a Game'**
  String get homeFindGame;

  /// No description provided for @homeLogSession.
  ///
  /// In en, this message translates to:
  /// **'Log Session'**
  String get homeLogSession;

  /// No description provided for @homeCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get homeCreateGame;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeRecentActivity;

  /// No description provided for @homeNoRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'No recent sessions'**
  String get homeNoRecentSessions;

  /// No description provided for @homeLogASession.
  ///
  /// In en, this message translates to:
  /// **'Log a session'**
  String get homeLogASession;

  /// No description provided for @homeNoUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'No upcoming games'**
  String get homeNoUpcomingGames;

  /// No description provided for @homeBrowseGames.
  ///
  /// In en, this message translates to:
  /// **'Browse games'**
  String get homeBrowseGames;

  /// No description provided for @homeNearbyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby games'**
  String get homeNearbyLoadFailed;

  /// No description provided for @homeNothingNearby.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby right now'**
  String get homeNothingNearby;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your squad. Play your game.'**
  String get homeTagline;

  /// No description provided for @homeNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotificationsTooltip;

  /// No description provided for @homeMyCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'My calendar'**
  String get homeMyCalendarTooltip;

  /// No description provided for @homeAddGame.
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get homeAddGame;

  /// No description provided for @homeLogTraining.
  ///
  /// In en, this message translates to:
  /// **'Log Training'**
  String get homeLogTraining;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search games, players…'**
  String get searchHint;

  /// No description provided for @searchCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get searchCloseTooltip;

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

  /// No description provided for @searchGamesError.
  ///
  /// In en, this message translates to:
  /// **'Games: {error}'**
  String searchGamesError(String error);

  /// No description provided for @searchPlayersError.
  ///
  /// In en, this message translates to:
  /// **'Players: {error}'**
  String searchPlayersError(String error);

  /// No description provided for @searchChipNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby games'**
  String get searchChipNearby;

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

  /// No description provided for @sportVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get sportVolleyball;

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

  /// No description provided for @sportCricket.
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get sportCricket;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @gamesCreateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create game'**
  String get gamesCreateTooltip;

  /// No description provided for @gamesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search games, sports, locations…'**
  String get gamesSearchHint;

  /// No description provided for @gamesFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get gamesFilterTooltip;

  /// No description provided for @gamesFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter active} other{{count} filters active}}'**
  String gamesFiltersActive(int count);

  /// No description provided for @gamesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get gamesNoneFound;

  /// No description provided for @gamesNoneFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or create a new game.'**
  String get gamesNoneFoundHint;

  /// No description provided for @gamesCreateAGame.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get gamesCreateAGame;

  /// No description provided for @skillAnyLevel.
  ///
  /// In en, this message translates to:
  /// **'Any level'**
  String get skillAnyLevel;

  /// No description provided for @commonClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get commonClearAll;

  /// No description provided for @commonSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get commonSport;

  /// No description provided for @gamesFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Games'**
  String get gamesFilterTitle;

  /// No description provided for @gamesFilterNearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get gamesFilterNearMe;

  /// No description provided for @gamesFilterNearMeHint.
  ///
  /// In en, this message translates to:
  /// **'Show games closest to your current location'**
  String get gamesFilterNearMeHint;

  /// No description provided for @gamesFilterCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. London'**
  String get gamesFilterCityHint;

  /// No description provided for @gamesFilterSkillTitle.
  ///
  /// In en, this message translates to:
  /// **'Required skill level'**
  String get gamesFilterSkillTitle;

  /// No description provided for @gamesFilterGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get gamesFilterGettingLocation;

  /// No description provided for @gamesFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get gamesFilterApply;

  /// No description provided for @gamesPlayersOf.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} players'**
  String gamesPlayersOf(int current, int max);

  /// No description provided for @gamesPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String gamesPendingCount(int count);

  /// No description provided for @gamesJoinGame.
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get gamesJoinGame;

  /// No description provided for @gamesRoster.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get gamesRoster;

  /// No description provided for @gamesStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gamesStatusOpen;

  /// No description provided for @gamesStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get gamesStatusFull;

  /// No description provided for @gamesStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get gamesStatusLive;

  /// No description provided for @gamesStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gamesStatusDone;

  /// No description provided for @gamesStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get gamesStatusCancelled;

  /// No description provided for @gamesFullBadge.
  ///
  /// In en, this message translates to:
  /// **'FULL'**
  String get gamesFullBadge;

  /// No description provided for @gamesDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String gamesDistanceMeters(int meters);

  /// No description provided for @gamesDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String gamesDistanceKm(String km);

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'My Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarNoGamesOnDay.
  ///
  /// In en, this message translates to:
  /// **'No games on this day'**
  String get calendarNoGamesOnDay;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get calendarFormatTwoWeeks;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarFormatWeek;

  /// No description provided for @gamesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No games} =1{1 game} other{{count} games}}'**
  String gamesCount(int count);

  /// No description provided for @commonLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is needed to find games near you. Enable it in settings or use city search.'**
  String get commonLocationPermissionDenied;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get commonSaveChanges;

  /// No description provided for @gameCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get gameCreateTitle;

  /// No description provided for @gameCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Game 🎮'**
  String get gameCreateButton;

  /// No description provided for @gameCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game created! 🎉'**
  String get gameCreateSuccess;

  /// No description provided for @gameEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get gameEditTitle;

  /// No description provided for @gameEditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Game updated.'**
  String get gameEditUpdated;

  /// No description provided for @gameFormSportLabel.
  ///
  /// In en, this message translates to:
  /// **'Sport *'**
  String get gameFormSportLabel;

  /// No description provided for @gameFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Game title *'**
  String get gameFormTitleLabel;

  /// No description provided for @gameFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunday 5-a-side'**
  String get gameFormTitleHint;

  /// No description provided for @gameFormTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get gameFormTitleRequired;

  /// No description provided for @gameFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get gameFormDescriptionLabel;

  /// No description provided for @gameFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional details, rules, what to bring…'**
  String get gameFormDescriptionHint;

  /// No description provided for @gameFormDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time *'**
  String get gameFormDateTime;

  /// No description provided for @gameFormDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {hours}h {minutes}m'**
  String gameFormDuration(int hours, String minutes);

  /// No description provided for @gameFormDurationSlider.
  ///
  /// In en, this message translates to:
  /// **'{minutes}min'**
  String gameFormDurationSlider(int minutes);

  /// No description provided for @gameFormLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get gameFormLocationRequired;

  /// No description provided for @gameFormAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get gameFormAddressLabel;

  /// No description provided for @gameFormAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing an address...'**
  String get gameFormAddressHint;

  /// No description provided for @gameFormAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a valid address from suggestions'**
  String get gameFormAddressInvalid;

  /// No description provided for @gameFormAddressNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Could not verify this address. Please choose another one.'**
  String get gameFormAddressNotVerified;

  /// No description provided for @gameFormAddressSelectFromList.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid address from suggestions.'**
  String get gameFormAddressSelectFromList;

  /// No description provided for @gameFormNeighborhoodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shoreditch'**
  String get gameFormNeighborhoodHint;

  /// No description provided for @gameFormVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get gameFormVenueLabel;

  /// No description provided for @gameFormVenueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hackney Marshes'**
  String get gameFormVenueHint;

  /// No description provided for @gameFormCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get gameFormCityLabel;

  /// No description provided for @gameFormCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. London'**
  String get gameFormCityHint;

  /// No description provided for @gameFormMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Max players: {count}'**
  String gameFormMaxPlayers(int count);

  /// No description provided for @gameFormVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get gameFormVisibility;

  /// No description provided for @gameFormPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Game (Requires Approval)'**
  String get gameFormPrivateTitle;

  /// No description provided for @gameFormPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden from public search. Every join request will require your approval.'**
  String get gameFormPrivateHint;

  /// No description provided for @gameFormPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Public — anyone can find and join this game.'**
  String get gameFormPublicHint;

  /// No description provided for @gameFormDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get gameFormDetails;

  /// No description provided for @gameFormSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get gameFormSchedule;

  /// No description provided for @gameFormLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get gameFormLocation;

  /// No description provided for @gameEditTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get gameEditTitleLabel;

  /// No description provided for @gameEditTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Game title'**
  String get gameEditTitleHint;

  /// No description provided for @gameEditTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get gameEditTitleRequired;

  /// No description provided for @gameEditDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {minutes}min'**
  String gameEditDuration(int minutes);

  /// No description provided for @gameEditSliderMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String gameEditSliderMinutes(int minutes);

  /// No description provided for @gameEditAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get gameEditAddressLabel;

  /// No description provided for @gameEditAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Selected address'**
  String get gameEditAddressHint;

  /// No description provided for @gameEditCityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get gameEditCityHint;

  /// No description provided for @gameEditCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required.'**
  String get gameEditCityRequired;

  /// No description provided for @gameEditNeighborhoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get gameEditNeighborhoodLabel;

  /// No description provided for @gameEditVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get gameEditVenueLabel;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @gamesStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get gamesStatusCompleted;

  /// No description provided for @gameDurationMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes}min'**
  String gameDurationMin(Object minutes);

  /// No description provided for @gameDurationHr.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String gameDurationHr(Object hours);

  /// No description provided for @gameDurationHrMin.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}min'**
  String gameDurationHrMin(Object hours, Object minutes);

  /// No description provided for @gameDetailRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your request to join was declined. You can try again below.'**
  String get gameDetailRequestDeclined;

  /// No description provided for @gameDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get gameDetailDate;

  /// No description provided for @gameDetailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get gameDetailTime;

  /// No description provided for @gameDetailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get gameDetailDuration;

  /// No description provided for @gameDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About this game'**
  String get gameDetailAbout;

  /// No description provided for @gameDetailOrganiser.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get gameDetailOrganiser;

  /// No description provided for @gameDetailPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get gameDetailPlayers;

  /// No description provided for @gameDetailResult.
  ///
  /// In en, this message translates to:
  /// **'Match Result'**
  String get gameDetailResult;

  /// No description provided for @gameDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get gameDetailTags;

  /// No description provided for @gameDetailReport.
  ///
  /// In en, this message translates to:
  /// **'Report Game'**
  String get gameDetailReport;

  /// No description provided for @gameDetailMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get gameDetailMapUnavailable;

  /// No description provided for @gameDetailApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get gameDetailApproved;

  /// No description provided for @gameDetailPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get gameDetailPendingRequests;

  /// No description provided for @gameDetailRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get gameDetailRate;

  /// No description provided for @gameDetailApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get gameDetailApprove;

  /// No description provided for @gameDetailKick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get gameDetailKick;

  /// No description provided for @gameDetailRatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Rate participants below to share how the game went.'**
  String get gameDetailRatePrompt;

  /// No description provided for @gameDetailChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get gameDetailChat;

  /// No description provided for @gameDetailRateParticipants.
  ///
  /// In en, this message translates to:
  /// **'Rate Participants'**
  String get gameDetailRateParticipants;

  /// No description provided for @gameDetailGameCompleted.
  ///
  /// In en, this message translates to:
  /// **'Game Completed'**
  String get gameDetailGameCompleted;

  /// No description provided for @gameDetailManage.
  ///
  /// In en, this message translates to:
  /// **'Manage (Organiser)'**
  String get gameDetailManage;

  /// No description provided for @gameDetailGameFull.
  ///
  /// In en, this message translates to:
  /// **'Game is Full'**
  String get gameDetailGameFull;

  /// No description provided for @gameDetailRequestToJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get gameDetailRequestToJoin;

  /// No description provided for @gameDetailLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave Game'**
  String get gameDetailLeave;

  /// No description provided for @gameDetailInvitedBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to this game'**
  String get gameDetailInvitedBanner;

  /// No description provided for @gameDetailAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get gameDetailAcceptInvite;

  /// No description provided for @gameDetailDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get gameDetailDecline;

  /// No description provided for @gameDetailPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending approval'**
  String get gameDetailPendingBanner;

  /// No description provided for @gameDetailWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get gameDetailWithdraw;

  /// No description provided for @gameDetailInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get gameDetailInviteFriends;

  /// No description provided for @gameDetailNoFriends.
  ///
  /// In en, this message translates to:
  /// **'Add friends from their profile to invite them to games.'**
  String get gameDetailNoFriends;

  /// No description provided for @gameDetailInvitedChip.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get gameDetailInvitedChip;

  /// No description provided for @gameDetailMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge game?'**
  String get gameDetailMergeTitle;

  /// No description provided for @gameDetailMergeButton.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get gameDetailMergeButton;

  /// No description provided for @gameDetailCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase capacity?'**
  String get gameDetailCapacityTitle;

  /// No description provided for @gameDetailCapacityBody.
  ///
  /// In en, this message translates to:
  /// **'The target game is too full for this merge. Expand its capacity and complete the merge?'**
  String get gameDetailCapacityBody;

  /// No description provided for @gameDetailForceMerge.
  ///
  /// In en, this message translates to:
  /// **'Force merge'**
  String get gameDetailForceMerge;

  /// No description provided for @gameDetailMergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game merged successfully.'**
  String get gameDetailMergeSuccess;

  /// No description provided for @gameDetailMergeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge Game'**
  String get gameDetailMergeSheetTitle;

  /// No description provided for @gameDetailMergeNone.
  ///
  /// In en, this message translates to:
  /// **'No eligible open games found.'**
  String get gameDetailMergeNone;

  /// No description provided for @gameDetailInviteFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Send an invite to your approved friends'**
  String get gameDetailInviteFriendsHint;

  /// No description provided for @gameDetailMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Combine this game into another open game'**
  String get gameDetailMergeHint;

  /// No description provided for @gameDetailViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View Summary / Rate Players'**
  String get gameDetailViewSummary;

  /// No description provided for @gameDetailViewSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Game is finished — open the rating flow for participants.'**
  String get gameDetailViewSummaryHint;

  /// No description provided for @gameDetailCompleteGame.
  ///
  /// In en, this message translates to:
  /// **'Complete Game'**
  String get gameDetailCompleteGame;

  /// No description provided for @gameDetailCompleteGameHint.
  ///
  /// In en, this message translates to:
  /// **'Mark the game as finished and open ratings for participants.'**
  String get gameDetailCompleteGameHint;

  /// No description provided for @gameDetailAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Game already cancelled'**
  String get gameDetailAlreadyCancelled;

  /// No description provided for @gameDetailCancelGame.
  ///
  /// In en, this message translates to:
  /// **'Cancel Game'**
  String get gameDetailCancelGame;

  /// No description provided for @gameDetailCancelled.
  ///
  /// In en, this message translates to:
  /// **'Game cancelled.'**
  String get gameDetailCancelled;

  /// No description provided for @gameDetailCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel game?'**
  String get gameDetailCancelConfirmTitle;

  /// No description provided for @gameDetailCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will mark the game as cancelled for all players.'**
  String get gameDetailCancelConfirmBody;

  /// No description provided for @gameDetailYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get gameDetailYesCancel;

  /// No description provided for @gameDetailCompleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete game?'**
  String get gameDetailCompleteConfirmTitle;

  /// No description provided for @gameDetailCompleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This marks the game as finished, updates player stats, and unlocks rating for all approved players. This action cannot be undone.'**
  String get gameDetailCompleteConfirmBody;

  /// No description provided for @gameDetailNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get gameDetailNotYet;

  /// No description provided for @gameDetailMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get gameDetailMarkCompleted;

  /// No description provided for @gameDetailPendingRatingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending ratings. Pull to refresh and try again.'**
  String get gameDetailPendingRatingsFailed;

  /// No description provided for @gameDetailPlayerFallback.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get gameDetailPlayerFallback;

  /// No description provided for @gameDetailAllRated.
  ///
  /// In en, this message translates to:
  /// **'Everyone in this game has been rated.'**
  String get gameDetailAllRated;

  /// No description provided for @gameDetailRateAParticipant.
  ///
  /// In en, this message translates to:
  /// **'Rate a participant'**
  String get gameDetailRateAParticipant;

  /// No description provided for @gameDetailWontRatePrompt.
  ///
  /// In en, this message translates to:
  /// **'You will not be prompted to rate this game.'**
  String get gameDetailWontRatePrompt;

  /// No description provided for @gameDetailDontRate.
  ///
  /// In en, this message translates to:
  /// **'Don\'t rate this game'**
  String get gameDetailDontRate;

  /// No description provided for @gameDetailCancelReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get gameDetailCancelReasonTitle;

  /// No description provided for @gameDetailCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weather, venue issue, not enough players…'**
  String get gameDetailCancelReasonHint;

  /// No description provided for @gameDetailCancelGameButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel game'**
  String get gameDetailCancelGameButton;

  /// No description provided for @gameDetailPlayerYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (You)'**
  String gameDetailPlayerYou(String name);

  /// No description provided for @gameDetailScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String gameDetailScore(String score);

  /// No description provided for @gameDetailWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {winner}'**
  String gameDetailWinner(String winner);

  /// No description provided for @gameDetailInvitedName.
  ///
  /// In en, this message translates to:
  /// **'Invited {name}'**
  String gameDetailInvitedName(String name);

  /// No description provided for @gameDetailRevokedName.
  ///
  /// In en, this message translates to:
  /// **'Revoked invite for {name}'**
  String gameDetailRevokedName(String name);

  /// No description provided for @gameDetailMergeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Merge \'{source}\' into \'{target}\'?\nYour game will be cancelled and players moved to the target.'**
  String gameDetailMergeConfirmBody(String source, String target);

  /// No description provided for @gameDetailMergePick.
  ///
  /// In en, this message translates to:
  /// **'Pick an open {sport} game in {city}.'**
  String gameDetailMergePick(String sport, String city);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get commonAccept;

  /// No description provided for @commonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonDecline;

  /// No description provided for @commonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApprove;

  /// No description provided for @commonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get commonReject;

  /// No description provided for @chatTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitleFallback;

  /// No description provided for @chatNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatNewMessage;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get chatLoadFailed;

  /// No description provided for @chatNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversations;

  /// No description provided for @chatNoConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by tapping the edit icon above or opening a game and tapping Chat.'**
  String get chatNoConversationsHint;

  /// No description provided for @chatNoLongerParticipant.
  ///
  /// In en, this message translates to:
  /// **'You are no longer a participant in this chat.'**
  String get chatNoLongerParticipant;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatMessageHint;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesYet;

  /// No description provided for @chatEdited.
  ///
  /// In en, this message translates to:
  /// **'• edited'**
  String get chatEdited;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMessageDeleted;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get chatCopyText;

  /// No description provided for @chatUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatUnpin;

  /// No description provided for @chatPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin message'**
  String get chatPinMessage;

  /// No description provided for @chatPinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get chatPinnedMessage;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsAllCaughtUp;

  /// No description provided for @notificationsAllCaughtUpHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when something new happens.'**
  String get notificationsAllCaughtUpHint;

  /// No description provided for @notificationsAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated the players for this game.'**
  String get notificationsAlreadyRated;

  /// No description provided for @notificationsFriendAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get notificationsFriendAccepted;

  /// No description provided for @notificationsFriendDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get notificationsFriendDeclined;

  /// No description provided for @notificationsFriendUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update friend request'**
  String get notificationsFriendUpdateFailed;

  /// No description provided for @notificationsJoinedGame.
  ///
  /// In en, this message translates to:
  /// **'You joined the game.'**
  String get notificationsJoinedGame;

  /// No description provided for @notificationsInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined.'**
  String get notificationsInviteDeclined;

  /// No description provided for @notificationsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed.'**
  String get notificationsActionFailed;

  /// No description provided for @notificationsInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer valid.'**
  String get notificationsInviteInvalid;

  /// No description provided for @notificationsPlayerApproved.
  ///
  /// In en, this message translates to:
  /// **'Player approved.'**
  String get notificationsPlayerApproved;

  /// No description provided for @notificationsJoinRejected.
  ///
  /// In en, this message translates to:
  /// **'Join request rejected.'**
  String get notificationsJoinRejected;

  /// No description provided for @notificationsRelNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get notificationsRelNow;

  /// No description provided for @chatMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String chatMembersCount(int count);

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @notificationsRelMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String notificationsRelMinutes(int count);

  /// No description provided for @notificationsRelHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String notificationsRelHours(int count);

  /// No description provided for @notificationsRelDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String notificationsRelDays(int count);

  /// No description provided for @notificationsRelWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w'**
  String notificationsRelWeeks(int count);

  /// No description provided for @chatTypingOne.
  ///
  /// In en, this message translates to:
  /// **'{names} is typing...'**
  String chatTypingOne(String names);

  /// No description provided for @chatTypingMany.
  ///
  /// In en, this message translates to:
  /// **'{names} are typing...'**
  String chatTypingMany(String names);
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
