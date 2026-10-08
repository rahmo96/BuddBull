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
