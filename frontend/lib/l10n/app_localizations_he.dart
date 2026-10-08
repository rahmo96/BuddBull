// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get languageTitle => 'שפה';

  @override
  String get languageDeviceDefault => 'ברירת המחדל של המכשיר';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get commonCancel => 'ביטול';

  @override
  String get commonRetry => 'ניסיון חוזר';

  @override
  String get commonOops => 'אופס!';

  @override
  String get validationFieldRequired => 'שדה חובה.';

  @override
  String get validationInvalidEmail => 'יש להזין כתובת אימייל תקינה.';

  @override
  String get validationPasswordTooShort => 'הסיסמה חייבת להכיל לפחות 8 תווים.';

  @override
  String get validationPasswordsNoMatch => 'הסיסמאות אינן תואמות.';

  @override
  String get validationUsernameTooShort =>
      'שם המשתמש חייב להכיל לפחות 3 תווים.';

  @override
  String get validationAcceptTerms => 'יש לאשר את תנאי השימוש.';

  @override
  String get authWelcomeBack => 'ברוכים השבים!';

  @override
  String get authLoginSubtitle => 'התחברו לחשבון BuddBull שלכם';

  @override
  String get authEmailLabel => 'כתובת אימייל';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordLabel => 'סיסמה';

  @override
  String get authPasswordHint => 'הסיסמה שלכם';

  @override
  String get authForgotPassword => 'שכחתם סיסמה?';

  @override
  String get authLoginButton => 'התחברות';

  @override
  String get authNoAccount => 'אין לכם חשבון?';

  @override
  String get authSignUpLink => 'הרשמה';

  @override
  String get authRegisterTitle => 'יצירת חשבון';

  @override
  String get authRegisterSubtitle => 'הצטרפו ל-BuddBull — זה בחינם!';

  @override
  String get authFirstNameLabel => 'שם פרטי';

  @override
  String get authFirstNameHint => 'דנה';

  @override
  String get authLastNameLabel => 'שם משפחה';

  @override
  String get authLastNameHint => 'לוי';

  @override
  String get authUsernameLabel => 'שם משתמש';

  @override
  String get authUsernameHint => '@username';

  @override
  String get authNewPasswordHint => 'לפחות 8 תווים';

  @override
  String get authConfirmPasswordLabel => 'אישור סיסמה';

  @override
  String get authConfirmPasswordHint => 'הקלידו שוב את הסיסמה';

  @override
  String get authTermsAgreement => 'אני מאשר/ת את ';

  @override
  String get authTermsOfService => 'תנאי השימוש';

  @override
  String get authTermsAnd => ' ואת ';

  @override
  String get authPrivacyPolicy => 'מדיניות הפרטיות';

  @override
  String get authRegisterButton => 'יצירת חשבון';

  @override
  String get authHaveAccount => 'כבר יש לכם חשבון?';

  @override
  String get authSignInLink => 'התחברות';

  @override
  String get authResetPasswordTitle => 'איפוס סיסמה';

  @override
  String get authForgotSubtitle =>
      'הזינו את כתובת האימייל ונשלח לכם קישור לאיפוס.';

  @override
  String get authSendResetLink => 'שליחת קישור לאיפוס';

  @override
  String get authBackToLogin => 'חזרה להתחברות';

  @override
  String get authResetInfo =>
      'הקישור לאיפוס תקף ל-10 דקות. אם לא מצאתם את המייל, כדאי לבדוק בתיקיית הספאם.';

  @override
  String get authPasswordWeak => 'חלשה';

  @override
  String get authPasswordFair => 'בינונית';

  @override
  String get authPasswordGood => 'טובה';

  @override
  String get authPasswordStrong => 'חזקה';

  @override
  String get skillBeginner => 'מתחיל';

  @override
  String get skillAmateur => 'חובב';

  @override
  String get skillIntermediate => 'בינוני';

  @override
  String get skillAdvanced => 'מתקדם';

  @override
  String get skillProfessional => 'מקצועי';

  @override
  String get profileCityLabel => 'עיר';

  @override
  String get profileNeighborhoodLabel => 'שכונה';

  @override
  String onboardingStepOf(int step, int total) {
    return 'שלב $step מתוך $total';
  }

  @override
  String get onboardingWelcomeMessage =>
      'ברוכים הבאים ל-BuddBull! בואו נכיר אתכם קצת יותר.';

  @override
  String get onboardingSportsSection =>
      'אילו ענפי ספורט אתם אוהבים? הקישו כדי לבחור — אפשר לשנות בכל זמן.';

  @override
  String get onboardingSkillPerSport => 'הרמה שלכם בכל ענף';

  @override
  String get onboardingNext => 'הבא';

  @override
  String get onboardingBack => 'חזרה';

  @override
  String get onboardingSkip => 'דילוג';

  @override
  String get onboardingLocationTitle => 'איפה אתם גרים?';

  @override
  String get onboardingLocationSubtitle =>
      'אנחנו משתמשים באזור שלכם כדי להתאים לכם משחקים קרובים. בחרו עיר כדי להמשיך.';

  @override
  String get onboardingLocationCityHint => 'התחילו להקליד את שם העיר…';

  @override
  String get onboardingLocationNeighborhoodHint => 'אופציונלי — שכונה או אזור';

  @override
  String get onboardingProfileTitle => 'בואו נתאים אישית';

  @override
  String get onboardingProfileSubtitle =>
      'העלו תמונה או בחרו אווטאר של Buddy. תמיד אפשר לעדכן מאוחר יותר.';

  @override
  String get onboardingUploadPhoto => 'העלאה מהמכשיר';

  @override
  String get onboardingOrPickAvatar => 'או בחרו אווטאר התחלתי';

  @override
  String get onboardingFinish => 'בואו נתחיל';
}
