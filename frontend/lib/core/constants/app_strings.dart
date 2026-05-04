/// All user-facing strings, centralised for future i18n.
abstract class AppStrings {
  // ── App ────────────────────────────────────────────────────────
  static const String appName = 'BuddBull';
  static const String appTagline = 'Find your squad. Play your game.';

  // ── Auth — Login ───────────────────────────────────────────────
  static const String welcomeBack = 'Welcome back!';
  static const String loginSubtitle = 'Sign in to your BuddBull account';
  static const String emailLabel = 'Email address';
  static const String emailHint = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Your password';
  static const String forgotPassword = 'Forgot password?';
  static const String loginButton = 'Sign In';
  static const String noAccount = "Don't have an account?";
  static const String signUpLink = 'Sign up';

  // ── Auth — Register ────────────────────────────────────────────
  static const String createAccount = 'Create Account';
  static const String registerSubtitle = 'Join BuddBull — it\'s free!';
  static const String firstNameLabel = 'First name';
  static const String firstNameHint = 'Alex';
  static const String lastNameLabel = 'Last name';
  static const String lastNameHint = 'Rivera';
  static const String usernameLabel = 'Username';
  static const String usernameHint = '@username';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String confirmPasswordHint = 'Repeat your password';
  static const String roleLabel = 'I want to…';
  static const String rolePlayer = 'Join games as a Player';
  static const String roleOrganizer = 'Organize & Captain games';
  static const String termsAgreement = 'I agree to the ';
  static const String termsOfService = 'Terms of Service';
  static const String andText = ' and ';
  static const String privacyPolicy = 'Privacy Policy';
  static const String registerButton = 'Create Account';
  static const String haveAccount = 'Already have an account?';
  static const String signInLink = 'Sign in';

  // ── Auth — Forgot Password ─────────────────────────────────────
  static const String resetPassword = 'Reset Password';
  static const String forgotSubtitle =
      'Enter your email and we\'ll send you a reset link.';
  static const String sendResetLink = 'Send Reset Link';
  static const String backToLogin = 'Back to Sign In';
  static const String resetEmailSent = 'Reset email sent! Check your inbox.';

  // ── Profile ────────────────────────────────────────────────────
  static const String myProfile = 'My Profile';
  static const String editProfile = 'Edit Profile';
  static const String bioLabel = 'Bio';
  static const String bioHint = 'Tell us a bit about yourself…';
  static const String cityLabel = 'City';
  static const String neighborhoodLabel = 'Neighbourhood';
  static const String radiusLabel = 'Search radius (km)';
  static const String sportsInterests = 'Sports & Skill Levels';
  static const String addSport = '+ Add sport';
  static const String saveChanges = 'Save Changes';
  static const String changePhoto = 'Change Photo';
  static const String followers = 'Followers';
  static const String following = 'Following';
  static const String gamesPlayed = 'Games';
  static const String rating = 'Rating';
  static const String streakDays = 'Streak';

  // ── Skill levels ───────────────────────────────────────────────
  static const String beginner = 'Beginner';
  static const String intermediate = 'Intermediate';
  static const String advanced = 'Advanced';
  static const String professional = 'Professional';

  // ── General ────────────────────────────────────────────────────
  static const String loading = 'Loading…';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String close = 'Close';

  // ── Validation ─────────────────────────────────────────────────
  static const String fieldRequired = 'This field is required.';
  static const String invalidEmail = 'Enter a valid email address.';
  static const String passwordTooShort = 'Password must be at least 8 characters.';
  static const String passwordsNoMatch = 'Passwords do not match.';
  static const String usernameTooShort = 'Username must be at least 3 characters.';
  static const String acceptTerms = 'You must accept the Terms of Service.';

  // ── Errors ─────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Check your network.';
  static const String serverError = 'Server error. Please try again later.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String unauthorised = 'You are not authorised to do that.';

  // ── Navigation labels ──────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navGames = 'Games';
  static const String navChat = 'Messages';
  static const String navPerformance = 'Performance';
  static const String navProfile = 'Profile';

  AppStrings._();
}
