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

  @override
  String get commonSeeAll => 'הצג הכול';

  @override
  String get commonBrowseAll => 'עיון בהכול';

  @override
  String get navHome => 'בית';

  @override
  String get navGames => 'משחקים';

  @override
  String get navChat => 'הודעות';

  @override
  String get navPerformance => 'ביצועים';

  @override
  String get navProfile => 'פרופיל';

  @override
  String get homeGreetingMorning => 'בוקר טוב';

  @override
  String get homeGreetingAfternoon => 'צהריים טובים';

  @override
  String get homeGreetingEvening => 'ערב טוב';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String homeGreetingNoName(String greeting) {
    return '$greeting!';
  }

  @override
  String get homeStatGames => 'משחקים';

  @override
  String get homeStatRating => 'דירוג';

  @override
  String get homeStatStreak => 'רצף';

  @override
  String homeStreakDaysShort(int count) {
    return '$count ימים';
  }

  @override
  String get homeMyUpcomingGames => 'המשחקים הקרובים שלי';

  @override
  String get homeExploreNearYou => 'משחקים לידך';

  @override
  String get homeQuickActions => 'פעולות מהירות';

  @override
  String get homeFindGame => 'מצאו משחק';

  @override
  String get homeLogSession => 'תיעוד אימון';

  @override
  String get homeCreateGame => 'יצירת משחק';

  @override
  String get homeRecentActivity => 'פעילות אחרונה';

  @override
  String get homeNoRecentSessions => 'אין אימונים אחרונים';

  @override
  String get homeLogASession => 'תיעוד אימון';

  @override
  String get homeNoUpcomingGames => 'אין משחקים קרובים';

  @override
  String get homeBrowseGames => 'עיון במשחקים';

  @override
  String get homeNearbyLoadFailed => 'לא ניתן לטעון משחקים בסביבה';

  @override
  String get homeNothingNearby => 'אין כרגע משחקים בסביבה';

  @override
  String get homeTagline => 'מצאו את החבורה. שחקו את המשחק.';

  @override
  String get homeNotificationsTooltip => 'התראות';

  @override
  String get homeMyCalendarTooltip => 'היומן שלי';

  @override
  String get homeAddGame => 'הוספת משחק';

  @override
  String get homeLogTraining => 'תיעוד אימון';

  @override
  String get searchHint => 'חיפוש משחקים, שחקנים…';

  @override
  String get searchCloseTooltip => 'סגירת החיפוש';

  @override
  String get searchMinChars => 'הקלידו לפחות 2 תווים כדי לחפש';

  @override
  String get searchNoResults => 'לא נמצאו תוצאות';

  @override
  String get searchNoResultsHint => 'נסו ענף ספורט, עיר או שם שחקן אחרים';

  @override
  String get searchSectionGames => 'משחקים';

  @override
  String get searchSectionPlayers => 'שחקנים';

  @override
  String searchGamesError(String error) {
    return 'משחקים: $error';
  }

  @override
  String searchPlayersError(String error) {
    return 'שחקנים: $error';
  }

  @override
  String get searchChipNearby => 'משחקים בסביבה';

  @override
  String get searchDiscoverTitle => 'גלו את המשחק הבא שלכם';

  @override
  String get searchDiscoverSubtitle =>
      'חפשו לפי ענף ספורט, עיר, שם משתמש או שם שחקן';

  @override
  String get sportFootball => 'כדורגל';

  @override
  String get sportBasketball => 'כדורסל';

  @override
  String get sportTennis => 'טניס';

  @override
  String get sportVolleyball => 'כדורעף';

  @override
  String get sportRunning => 'ריצה';

  @override
  String get sportSwimming => 'שחייה';

  @override
  String get sportCycling => 'רכיבה על אופניים';

  @override
  String get sportCricket => 'קריקט';

  @override
  String get commonAll => 'הכול';

  @override
  String get commonClear => 'ניקוי';

  @override
  String get gamesCreateTooltip => 'יצירת משחק';

  @override
  String get gamesSearchHint => 'חיפוש משחקים, ענפי ספורט, מיקומים…';

  @override
  String get gamesFilterTooltip => 'סינון';

  @override
  String gamesFiltersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count סינונים פעילים',
      two: 'שני סינונים פעילים',
      one: 'סינון אחד פעיל',
    );
    return '$_temp0';
  }

  @override
  String get gamesNoneFound => 'לא נמצאו משחקים';

  @override
  String get gamesNoneFoundHint => 'נסו לשנות את הסינון או ליצור משחק חדש.';

  @override
  String get gamesCreateAGame => 'יצירת משחק';

  @override
  String get skillAnyLevel => 'כל רמה';

  @override
  String get commonClearAll => 'ניקוי הכול';

  @override
  String get commonSport => 'ענף ספורט';

  @override
  String get gamesFilterTitle => 'סינון משחקים';

  @override
  String get gamesFilterNearMe => 'לידי';

  @override
  String get gamesFilterNearMeHint => 'הצג משחקים הקרובים למיקום הנוכחי שלך';

  @override
  String get gamesFilterCityHint => 'לדוגמה: תל אביב';

  @override
  String get gamesFilterSkillTitle => 'רמת מיומנות נדרשת';

  @override
  String get gamesFilterGettingLocation => 'מאתר מיקום…';

  @override
  String get gamesFilterApply => 'החלת סינון';

  @override
  String gamesPlayersOf(int current, int max) {
    return '$current/$max שחקנים';
  }

  @override
  String gamesPendingCount(int count) {
    return '$count ממתינים';
  }

  @override
  String get gamesJoinGame => 'הצטרפות למשחק';

  @override
  String get gamesRoster => 'הרכב';

  @override
  String get gamesStatusOpen => 'פתוח';

  @override
  String get gamesStatusFull => 'מלא';

  @override
  String get gamesStatusLive => 'מתקיים';

  @override
  String get gamesStatusDone => 'הסתיים';

  @override
  String get gamesStatusCancelled => 'בוטל';

  @override
  String get gamesFullBadge => 'מלא';

  @override
  String gamesDistanceMeters(int meters) {
    return 'במרחק $meters מ׳';
  }

  @override
  String gamesDistanceKm(String km) {
    return 'במרחק $km ק״מ';
  }

  @override
  String get calendarTitle => 'היומן שלי';

  @override
  String get calendarToday => 'היום';

  @override
  String get calendarNoGamesOnDay => 'אין משחקים ביום זה';

  @override
  String get calendarFormatMonth => 'חודש';

  @override
  String get calendarFormatTwoWeeks => 'שבועיים';

  @override
  String get calendarFormatWeek => 'שבוע';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count משחקים',
      two: 'שני משחקים',
      one: 'משחק אחד',
      zero: 'אין משחקים',
    );
    return '$_temp0';
  }

  @override
  String get commonLocationPermissionDenied =>
      'נדרשת גישה למיקום כדי למצוא משחקים לידכם. אפשרו אותה בהגדרות או השתמשו בחיפוש לפי עיר.';

  @override
  String get commonOptional => 'אופציונלי';

  @override
  String get commonSaveChanges => 'שמירת שינויים';

  @override
  String get gameCreateTitle => 'יצירת משחק';

  @override
  String get gameCreateButton => 'יצירת משחק 🎮';

  @override
  String get gameCreateSuccess => 'המשחק נוצר! 🎉';

  @override
  String get gameEditTitle => 'עריכת משחק';

  @override
  String get gameEditUpdated => 'המשחק עודכן.';

  @override
  String get gameFormSportLabel => 'ענף ספורט *';

  @override
  String get gameFormTitleLabel => 'כותרת המשחק *';

  @override
  String get gameFormTitleHint => 'לדוגמה: כדורגל חמישיות ביום ראשון';

  @override
  String get gameFormTitleRequired => 'יש להזין כותרת';

  @override
  String get gameFormDescriptionLabel => 'תיאור';

  @override
  String get gameFormDescriptionHint =>
      'פרטים נוספים, חוקים, מה להביא… (אופציונלי)';

  @override
  String get gameFormDateTime => 'תאריך ושעה *';

  @override
  String gameFormDuration(int hours, String minutes) {
    return 'משך: $hours שע׳ $minutes דק׳';
  }

  @override
  String gameFormDurationSlider(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String get gameFormLocationRequired => 'מיקום *';

  @override
  String get gameFormAddressLabel => 'כתובת *';

  @override
  String get gameFormAddressHint => 'התחילו להקליד כתובת...';

  @override
  String get gameFormAddressInvalid => 'יש לבחור כתובת תקינה מההצעות';

  @override
  String get gameFormAddressNotVerified =>
      'לא ניתן לאמת את הכתובת. נא לבחור כתובת אחרת.';

  @override
  String get gameFormAddressSelectFromList => 'נא לבחור כתובת תקינה מההצעות.';

  @override
  String get gameFormNeighborhoodHint => 'לדוגמה: פלורנטין';

  @override
  String get gameFormVenueLabel => 'שם המקום';

  @override
  String get gameFormVenueHint => 'לדוגמה: פארק הירקון';

  @override
  String get gameFormCityLabel => 'עיר *';

  @override
  String get gameFormCityHint => 'לדוגמה: תל אביב';

  @override
  String gameFormMaxPlayers(int count) {
    return 'מקסימום שחקנים: $count';
  }

  @override
  String get gameFormVisibility => 'חשיפה';

  @override
  String get gameFormPrivateTitle => 'משחק פרטי (דורש אישור)';

  @override
  String get gameFormPrivateHint =>
      'מוסתר מהחיפוש הציבורי. כל בקשת הצטרפות תדרוש את אישורכם.';

  @override
  String get gameFormPublicHint =>
      'ציבורי — כל אחד יכול למצוא את המשחק ולהצטרף.';

  @override
  String get gameFormDetails => 'פרטים';

  @override
  String get gameFormSchedule => 'לו״ז';

  @override
  String get gameFormLocation => 'מיקום';

  @override
  String get gameEditTitleLabel => 'כותרת *';

  @override
  String get gameEditTitleHint => 'כותרת המשחק';

  @override
  String get gameEditTitleRequired => 'יש להזין כותרת.';

  @override
  String gameEditDuration(int minutes) {
    return 'משך: $minutes דק׳';
  }

  @override
  String gameEditSliderMinutes(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String get gameEditAddressLabel => 'כתובת';

  @override
  String get gameEditAddressHint => 'הכתובת שנבחרה';

  @override
  String get gameEditCityHint => 'עיר';

  @override
  String get gameEditCityRequired => 'יש להזין עיר.';

  @override
  String get gameEditNeighborhoodLabel => 'שכונה';

  @override
  String get gameEditVenueLabel => 'מקום';

  @override
  String get commonBack => 'חזרה';

  @override
  String get commonNo => 'לא';

  @override
  String get gamesStatusCompleted => 'הושלם';

  @override
  String gameDurationMin(Object minutes) {
    return '$minutes דק׳';
  }

  @override
  String gameDurationHr(Object hours) {
    return '$hours שע׳';
  }

  @override
  String gameDurationHrMin(Object hours, Object minutes) {
    return '$hours שע׳ $minutes דק׳';
  }

  @override
  String get gameDetailRequestDeclined =>
      'בקשת ההצטרפות שלכם נדחתה. אפשר לנסות שוב למטה.';

  @override
  String get gameDetailDate => 'תאריך';

  @override
  String get gameDetailTime => 'שעה';

  @override
  String get gameDetailDuration => 'משך';

  @override
  String get gameDetailAbout => 'על המשחק';

  @override
  String get gameDetailOrganiser => 'מארגן/ת';

  @override
  String get gameDetailPlayers => 'שחקנים';

  @override
  String get gameDetailResult => 'תוצאת המשחק';

  @override
  String get gameDetailTags => 'תגיות';

  @override
  String get gameDetailReport => 'דיווח על המשחק';

  @override
  String get gameDetailMapUnavailable => 'תצוגת המפה אינה זמינה';

  @override
  String get gameDetailApproved => 'מאושרים';

  @override
  String get gameDetailPendingRequests => 'בקשות ממתינות';

  @override
  String get gameDetailRate => 'דירוג';

  @override
  String get gameDetailApprove => 'אישור';

  @override
  String get gameDetailKick => 'הסרה';

  @override
  String get gameDetailRatePrompt =>
      'דרגו את המשתתפים למטה ושתפו איך עבר המשחק.';

  @override
  String get gameDetailChat => 'צ\'אט';

  @override
  String get gameDetailRateParticipants => 'דירוג משתתפים';

  @override
  String get gameDetailGameCompleted => 'המשחק הסתיים';

  @override
  String get gameDetailManage => 'ניהול (מארגן/ת)';

  @override
  String get gameDetailGameFull => 'המשחק מלא';

  @override
  String get gameDetailRequestToJoin => 'בקשת הצטרפות';

  @override
  String get gameDetailLeave => 'עזיבת המשחק';

  @override
  String get gameDetailInvitedBanner => 'הוזמנתם למשחק הזה';

  @override
  String get gameDetailAcceptInvite => 'אישור הזמנה';

  @override
  String get gameDetailDecline => 'דחייה';

  @override
  String get gameDetailPendingBanner => 'הבקשה שלכם ממתינה לאישור';

  @override
  String get gameDetailWithdraw => 'ביטול הבקשה';

  @override
  String get gameDetailInviteFriends => 'הזמנת חברים';

  @override
  String get gameDetailNoFriends =>
      'הוסיפו חברים מהפרופיל שלהם כדי להזמין אותם למשחקים.';

  @override
  String get gameDetailInvitedChip => 'הוזמן';

  @override
  String get gameDetailMergeTitle => 'למזג את המשחק?';

  @override
  String get gameDetailMergeButton => 'מיזוג';

  @override
  String get gameDetailCapacityTitle => 'להגדיל את הקיבולת?';

  @override
  String get gameDetailCapacityBody =>
      'משחק היעד מלא מדי למיזוג הזה. להרחיב את הקיבולת ולהשלים את המיזוג?';

  @override
  String get gameDetailForceMerge => 'מיזוג בכל זאת';

  @override
  String get gameDetailMergeSuccess => 'המשחקים מוזגו בהצלחה.';

  @override
  String get gameDetailMergeSheetTitle => 'מיזוג משחק';

  @override
  String get gameDetailMergeNone => 'לא נמצאו משחקים פתוחים מתאימים.';

  @override
  String get gameDetailInviteFriendsHint => 'שלחו הזמנה לחברים המאושרים שלכם';

  @override
  String get gameDetailMergeHint => 'מזגו את המשחק הזה למשחק פתוח אחר';

  @override
  String get gameDetailViewSummary => 'צפייה בסיכום / דירוג שחקנים';

  @override
  String get gameDetailViewSummaryHint =>
      'המשחק הסתיים — פתחו את תהליך הדירוג של המשתתפים.';

  @override
  String get gameDetailCompleteGame => 'סיום המשחק';

  @override
  String get gameDetailCompleteGameHint =>
      'סמנו את המשחק כהסתיים ופתחו דירוג למשתתפים.';

  @override
  String get gameDetailAlreadyCancelled => 'המשחק כבר בוטל';

  @override
  String get gameDetailCancelGame => 'ביטול המשחק';

  @override
  String get gameDetailCancelled => 'המשחק בוטל.';

  @override
  String get gameDetailCancelConfirmTitle => 'לבטל את המשחק?';

  @override
  String get gameDetailCancelConfirmBody =>
      'המשחק יסומן כמבוטל עבור כל השחקנים.';

  @override
  String get gameDetailYesCancel => 'כן, לבטל';

  @override
  String get gameDetailCompleteConfirmTitle => 'לסיים את המשחק?';

  @override
  String get gameDetailCompleteConfirmBody =>
      'הפעולה תסמן את המשחק כהסתיים, תעדכן את סטטיסטיקות השחקנים ותפתח דירוג לכל השחקנים המאושרים. אי אפשר לבטל פעולה זו.';

  @override
  String get gameDetailNotYet => 'עדיין לא';

  @override
  String get gameDetailMarkCompleted => 'סימון כהסתיים';

  @override
  String get gameDetailPendingRatingsFailed =>
      'לא ניתן לטעון דירוגים ממתינים. משכו לרענון ונסו שוב.';

  @override
  String get gameDetailPlayerFallback => 'שחקן/ית';

  @override
  String get gameDetailAllRated => 'כל המשתתפים במשחק זה כבר דורגו.';

  @override
  String get gameDetailRateAParticipant => 'דירוג משתתף';

  @override
  String get gameDetailWontRatePrompt => 'לא נבקש מכם לדרג את המשחק הזה.';

  @override
  String get gameDetailDontRate => 'לא לדרג את המשחק הזה';

  @override
  String get gameDetailCancelReasonTitle => 'סיבת הביטול';

  @override
  String get gameDetailCancelReasonHint =>
      'לדוגמה: מזג אוויר, בעיה במקום, אין מספיק שחקנים…';

  @override
  String get gameDetailCancelGameButton => 'ביטול המשחק';

  @override
  String gameDetailPlayerYou(String name) {
    return '$name (את/ה)';
  }

  @override
  String gameDetailScore(String score) {
    return 'תוצאה: $score';
  }

  @override
  String gameDetailWinner(String winner) {
    return 'מנצח/ת: $winner';
  }

  @override
  String gameDetailInvitedName(String name) {
    return '$name הוזמן/ה';
  }

  @override
  String gameDetailRevokedName(String name) {
    return 'ההזמנה של $name בוטלה';
  }

  @override
  String gameDetailMergeConfirmBody(String source, String target) {
    return 'למזג את \'$source\' אל \'$target\'?\nהמשחק שלכם יבוטל והשחקנים יועברו למשחק היעד.';
  }

  @override
  String gameDetailMergePick(String sport, String city) {
    return 'בחרו משחק $sport פתוח ב$city.';
  }

  @override
  String get commonDelete => 'מחיקה';

  @override
  String get commonAccept => 'אישור';

  @override
  String get commonDecline => 'דחייה';

  @override
  String get commonApprove => 'אישור';

  @override
  String get commonReject => 'דחייה';

  @override
  String get chatTitleFallback => 'צ\'אט';

  @override
  String get chatNewMessage => 'הודעה חדשה';

  @override
  String get chatLoadFailed => 'טעינת הצ\'אטים נכשלה';

  @override
  String get chatNoConversations => 'אין עדיין שיחות';

  @override
  String get chatNoConversationsHint =>
      'התחילו שיחה בלחיצה על סמל העריכה למעלה, או פתחו משחק ולחצו על צ\'אט.';

  @override
  String get chatNoLongerParticipant => 'אינכם משתתפים בצ\'אט הזה יותר.';

  @override
  String get chatMessageHint => 'הקלידו הודעה...';

  @override
  String get chatYesterday => 'אתמול';

  @override
  String get chatNoMessagesYet => 'אין עדיין הודעות';

  @override
  String get chatEdited => '• נערכה';

  @override
  String get chatMessageDeleted => 'ההודעה נמחקה';

  @override
  String get chatReply => 'תגובה';

  @override
  String get chatCopyText => 'העתקת טקסט';

  @override
  String get chatUnpin => 'ביטול הצמדה';

  @override
  String get chatPinMessage => 'הצמדת הודעה';

  @override
  String get chatPinnedMessage => 'הודעה מוצמדת';

  @override
  String get notificationsTitle => 'התראות';

  @override
  String get notificationsMarkAllRead => 'סימון הכול כנקרא';

  @override
  String get notificationsAllCaughtUp => 'אתם מעודכנים';

  @override
  String get notificationsAllCaughtUpHint => 'נעדכן אתכם כשיקרה משהו חדש.';

  @override
  String get notificationsAlreadyRated => 'כבר דירגתם את השחקנים במשחק הזה.';

  @override
  String get notificationsFriendAccepted => 'בקשת החברות אושרה';

  @override
  String get notificationsFriendDeclined => 'בקשת החברות נדחתה';

  @override
  String get notificationsFriendUpdateFailed => 'לא ניתן לעדכן את בקשת החברות';

  @override
  String get notificationsJoinedGame => 'הצטרפתם למשחק.';

  @override
  String get notificationsInviteDeclined => 'ההזמנה נדחתה.';

  @override
  String get notificationsActionFailed => 'הפעולה נכשלה.';

  @override
  String get notificationsInviteInvalid => 'ההזמנה אינה תקפה יותר.';

  @override
  String get notificationsPlayerApproved => 'השחקן אושר.';

  @override
  String get notificationsJoinRejected => 'בקשת ההצטרפות נדחתה.';

  @override
  String get notificationsRelNow => 'עכשיו';

  @override
  String chatMembersCount(int count) {
    return '$count חברים';
  }

  @override
  String chatReplyingTo(String name) {
    return 'משיבים ל$name';
  }

  @override
  String notificationsRelMinutes(int count) {
    return '$count דק׳';
  }

  @override
  String notificationsRelHours(int count) {
    return '$count שע׳';
  }

  @override
  String notificationsRelDays(int count) {
    return '$count ימ׳';
  }

  @override
  String notificationsRelWeeks(int count) {
    return '$count שב׳';
  }

  @override
  String chatTypingOne(String names) {
    return '$names מקליד/ה...';
  }

  @override
  String chatTypingMany(String names) {
    return '$names מקלידים...';
  }
}
