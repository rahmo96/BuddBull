// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDeviceDefault => 'Device default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOops => 'Oops!';

  @override
  String get validationFieldRequired => 'This field is required.';

  @override
  String get validationInvalidEmail => 'Enter a valid email address.';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get validationPasswordsNoMatch => 'Passwords do not match.';

  @override
  String get validationUsernameTooShort =>
      'Username must be at least 3 characters.';

  @override
  String get validationAcceptTerms => 'You must accept the Terms of Service.';

  @override
  String get authWelcomeBack => 'Welcome back!';

  @override
  String get authLoginSubtitle => 'Sign in to your BuddBull account';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Your password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLoginButton => 'Sign In';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSignUpLink => 'Sign up';

  @override
  String get authRegisterTitle => 'Create Account';

  @override
  String get authRegisterSubtitle => 'Join BuddBull — it\'s free!';

  @override
  String get authFirstNameLabel => 'First name';

  @override
  String get authFirstNameHint => 'Alex';

  @override
  String get authLastNameLabel => 'Last name';

  @override
  String get authLastNameHint => 'Rivera';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameHint => '@username';

  @override
  String get authNewPasswordHint => 'At least 8 characters';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'Repeat your password';

  @override
  String get authTermsAgreement => 'I agree to the ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authTermsAnd => ' and ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authRegisterButton => 'Create Account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get authResetPasswordTitle => 'Reset Password';

  @override
  String get authForgotSubtitle =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authBackToLogin => 'Back to Sign In';

  @override
  String get authResetInfo =>
      'The reset link expires in 10 minutes. Check your spam folder if you don\'t see the email.';

  @override
  String get authPasswordWeak => 'Weak';

  @override
  String get authPasswordFair => 'Fair';

  @override
  String get authPasswordGood => 'Good';

  @override
  String get authPasswordStrong => 'Strong';

  @override
  String get skillBeginner => 'Beginner';

  @override
  String get skillAmateur => 'Amateur';

  @override
  String get skillIntermediate => 'Intermediate';

  @override
  String get skillAdvanced => 'Advanced';

  @override
  String get skillProfessional => 'Professional';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileNeighborhoodLabel => 'Neighbourhood';

  @override
  String onboardingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingWelcomeMessage =>
      'Welcome to BuddBull! Let\'s get to know you better.';

  @override
  String get onboardingSportsSection =>
      'What are your favourite sports? Tap to select — you can change this anytime.';

  @override
  String get onboardingSkillPerSport => 'Your level in each sport';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingLocationTitle => 'Where do you live?';

  @override
  String get onboardingLocationSubtitle =>
      'We use your area to match you with nearby games. Pick your city to continue.';

  @override
  String get onboardingLocationCityHint => 'Start typing your city…';

  @override
  String get onboardingLocationNeighborhoodHint =>
      'Optional — neighbourhood or area';

  @override
  String get onboardingProfileTitle => 'Make it yours';

  @override
  String get onboardingProfileSubtitle =>
      'Upload a photo or pick a Buddy avatar. You can always update later.';

  @override
  String get onboardingUploadPhoto => 'Upload from device';

  @override
  String get onboardingOrPickAvatar => 'Or choose a starter avatar';

  @override
  String get onboardingFinish => 'Get started';
}
