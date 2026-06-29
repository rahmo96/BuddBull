// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BuddBull';

  @override
  String get appTagline => 'Find your squad. Play your game.';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Sign in to your BuddBull account';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registerSubtitle => 'Join BuddBull — it\'s free!';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameHint => 'Alex';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get lastNameHint => 'Rivera';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => '@username';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Repeat your password';

  @override
  String get roleLabel => 'I want to…';

  @override
  String get rolePlayer => 'Join games as a Player';

  @override
  String get roleOrganizer => 'Organize & Captain games';

  @override
  String get termsAgreement => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get andText => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get registerButton => 'Create Account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get forgotSubtitle =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Sign In';

  @override
  String get resetEmailSent => 'Reset email sent! Check your inbox.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bioHint => 'Tell us a bit about yourself…';

  @override
  String get cityLabel => 'City';

  @override
  String get neighborhoodLabel => 'Neighbourhood';

  @override
  String get radiusLabel => 'Search radius (km)';

  @override
  String get sportsInterests => 'Sports & Skill Levels';

  @override
  String get addSport => '+ Add sport';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get friends => 'Friends';

  @override
  String get gamesPlayed => 'Games';

  @override
  String get rating => 'Rating';

  @override
  String get streakDays => 'Streak';

  @override
  String get beginner => 'Beginner';

  @override
  String get amateur => 'Amateur';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get professional => 'Professional';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters.';

  @override
  String get passwordsNoMatch => 'Passwords do not match.';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters.';

  @override
  String get acceptTerms => 'You must accept the Terms of Service.';

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
  String get locationPermissionDenied =>
      'Location access is needed to find games near you. Enable it in settings or use city search.';

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

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError => 'No internet connection. Check your network.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get unauthorised => 'You are not authorised to do that.';

  @override
  String get resourceNotFound => 'Resource not found.';

  @override
  String get conflictError => 'A conflict occurred.';

  @override
  String get badRequestError => 'Invalid request.';

  @override
  String get validationError => 'Validation failed.';

  @override
  String get rateLimitedError => 'Too many requests. Please slow down.';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navGames => 'Games';

  @override
  String get navChat => 'Messages';

  @override
  String get navPerformance => 'Performance';

  @override
  String get navProfile => 'Profile';

  @override
  String get oops => 'Oops!';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get searchGamesPlayersHint => 'Search games, players…';

  @override
  String get tooltipMyCalendar => 'My calendar';

  @override
  String get fabAddGame => 'Add Game';

  @override
  String get fabLogTraining => 'Log Training';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Receive notifications about activities';

  @override
  String get activityReminders => 'Activity Reminders';

  @override
  String get activityRemindersSubtitle =>
      'Remind me before scheduled activities';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Use dark theme';

  @override
  String get appVersion => 'App Version';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get remindersEnabled => 'Activity reminders enabled';

  @override
  String get remindersDisabled => 'Activity reminders disabled';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get darkModeDisabled => 'Dark mode disabled';

  @override
  String get tooltipAdminDashboard => 'Admin Dashboard';

  @override
  String get tooltipEditProfile => 'Edit profile';

  @override
  String get tooltipSignOut => 'Sign out';

  @override
  String mutualConnections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mutual connections',
      one: '1 mutual connection',
      zero: 'No mutual connections',
    );
    return '$_temp0';
  }

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionLocation => 'Location';

  @override
  String locationRadiusKm(int radius) {
    return '$radius km radius';
  }

  @override
  String get sectionRecentActivity => 'Recent Activity';

  @override
  String get dialogSignOutTitle => 'Sign out?';

  @override
  String get dialogSignOutBody => 'You will need to sign in again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get winRatePercent => 'Win Rate %';

  @override
  String communityAverageRating(String rating, int count, String ratingWord) {
    return 'Community average $rating from $count $ratingWord';
  }

  @override
  String get ratingSingular => 'rating';

  @override
  String get ratingsPlural => 'ratings';

  @override
  String get sectionSports => 'Sports';

  @override
  String get sectionRatingsSummary => 'Ratings Summary';

  @override
  String get metricOverall => 'Overall';

  @override
  String get metricReliability => 'Reliability';

  @override
  String get metricBehavior => 'Behavior';

  @override
  String get sectionUpcomingGames => 'Upcoming Games';

  @override
  String get snackFriendRequestSent => 'Friend request sent';

  @override
  String get snackNowFriends => 'You are now friends';

  @override
  String get snackFriendRequestDeclined => 'Friend request declined';

  @override
  String get snackSignInToMessage => 'Please sign in to send a message.';

  @override
  String get snackCannotMessageSelf => 'You cannot message yourself.';

  @override
  String get buttonMessage => 'Message';

  @override
  String get buttonRequestSent => 'Request sent';

  @override
  String get buttonAccept => 'Accept';

  @override
  String get buttonDecline => 'Decline';

  @override
  String get buttonAddFriend => 'Add Friend';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String activityDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get greetingGoodMorning => 'Good morning';

  @override
  String get greetingGoodAfternoon => 'Good afternoon';

  @override
  String get greetingGoodEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String firstName) {
    return '$greeting, $firstName!';
  }

  @override
  String greetingNoName(String greeting) {
    return '$greeting!';
  }

  @override
  String get homeCollapsedTitleFallback => 'BuddBull';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get statGames => 'Games';

  @override
  String get statRating => 'Rating';

  @override
  String get statStreak => 'Streak';

  @override
  String streakDaysSuffix(int days) {
    return '${days}d';
  }

  @override
  String get sectionMyUpcomingGames => 'My Upcoming Games';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get sectionExploreNearYou => 'Explore Near You';

  @override
  String get actionBrowseAll => 'Browse all';

  @override
  String get sectionQuickActions => 'Quick Actions';

  @override
  String get quickActionFindGame => 'Find a Game';

  @override
  String get quickActionLogSession => 'Log Session';

  @override
  String get quickActionCreateGame => 'Create Game';

  @override
  String get emptyNoRecentSessions => 'No recent sessions';

  @override
  String get actionLogSession => 'Log a session';

  @override
  String get emptyNoUpcomingGames => 'No upcoming games';

  @override
  String get actionBrowseGames => 'Browse games';

  @override
  String get emptyCouldntLoadNearbyGames => 'Couldn\'t load nearby games';

  @override
  String get emptyNothingNearby => 'Nothing nearby right now';

  @override
  String get tooltipCreateGame => 'Create game';

  @override
  String get searchGamesHint => 'Search games, sports, locations…';

  @override
  String get tooltipFilter => 'Filter';

  @override
  String get sportFilterAll => 'All';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportRunning => 'Running';

  @override
  String get sportSwimming => 'Swimming';

  @override
  String get sportCycling => 'Cycling';

  @override
  String get sportVolleyball => 'Volleyball';

  @override
  String get sportCricket => 'Cricket';

  @override
  String filtersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters active',
      one: '1 filter active',
    );
    return '$_temp0';
  }

  @override
  String get clearFilters => 'Clear';

  @override
  String get emptyNoGamesFound => 'No games found';

  @override
  String get emptyTryAdjustingFilters =>
      'Try adjusting your filters or create a new game.';

  @override
  String get buttonCreateGame => 'Create a game';

  @override
  String get filterGames => 'Filter Games';

  @override
  String get clearAll => 'Clear all';

  @override
  String get sport => 'Sport';

  @override
  String get nearMe => 'Near me';

  @override
  String get requiredSkillLevel => 'Required skill level';

  @override
  String get createGameTitle => 'Create Game';

  @override
  String get gameTitleLabel => 'Game title *';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dateAndTime => 'Date & Time *';

  @override
  String durationHours(int hours, int minutes) {
    return 'Duration: ${hours}h ${minutes}min';
  }

  @override
  String durationMinutesOnly(int minutes) {
    return '${minutes}min';
  }

  @override
  String get locationRequired => 'Location *';

  @override
  String get addressLabel => 'Address *';

  @override
  String get venueNameLabel => 'Venue name';

  @override
  String maxPlayersLabel(int count) {
    return 'Max players: $count';
  }

  @override
  String get visibility => 'Visibility';

  @override
  String get gameCreatedSuccess => 'Game created! 🎉';

  @override
  String get editGameTitle => 'Edit Game';

  @override
  String get gameUpdatedSuccess => 'Game updated!';

  @override
  String get myCalendar => 'My Calendar';

  @override
  String get today => 'Today';

  @override
  String get noGamesOnDay => 'No games on this day';

  @override
  String get joinRequestDeclinedSnack =>
      'Your request to join was declined. You can try again below.';

  @override
  String get infoLabelDate => 'Date';

  @override
  String get infoLabelTime => 'Time';

  @override
  String get infoLabelDuration => 'Duration';

  @override
  String get sectionAboutThisGame => 'About this game';

  @override
  String get sectionOrganiser => 'Organiser';

  @override
  String get sectionPlayers => 'Players';

  @override
  String get sectionMatchResult => 'Match Result';

  @override
  String get sectionTags => 'Tags';

  @override
  String get mapPreviewUnavailable => 'Map preview unavailable';

  @override
  String get playerListApproved => 'Approved';

  @override
  String get playerListPendingRequests => 'Pending requests';

  @override
  String get playerYouSuffix => '(You)';

  @override
  String get buttonRate => 'Rate';

  @override
  String get tooltipApprove => 'Approve';

  @override
  String get tooltipKick => 'Kick';

  @override
  String get ratePromptBanner =>
      'Rate participants below to share how the game went.';

  @override
  String matchResultScore(String score) {
    return 'Score: $score';
  }

  @override
  String matchResultWinner(String winner) {
    return 'Winner: $winner';
  }

  @override
  String get gameStatusOpen => 'Open';

  @override
  String get gameStatusFull => 'Full';

  @override
  String get gameStatusLive => 'Live';

  @override
  String get gameStatusCompleted => 'Completed';

  @override
  String get gameStatusCancelled => 'Cancelled';

  @override
  String get reportGame => 'Report Game';

  @override
  String get buttonChat => 'Chat';

  @override
  String get buttonRateParticipants => 'Rate Participants';

  @override
  String get buttonLeaveGame => 'Leave Game';

  @override
  String get buttonGameCompleted => 'Game Completed';

  @override
  String get buttonManageOrganiser => 'Manage (Organiser)';

  @override
  String get buttonGameIsFull => 'Game is Full';

  @override
  String get buttonRequestToJoin => 'Request to Join';

  @override
  String get buttonJoinGame => 'Join Game';

  @override
  String get inviteBannerTitle => 'You\'re invited to this game';

  @override
  String get buttonAcceptInvitation => 'Accept Invitation';

  @override
  String get pendingApprovalMessage => 'Your request is pending approval';

  @override
  String get buttonWithdraw => 'Withdraw';

  @override
  String get inviteFriendsSheetTitle => 'Invite Friends';

  @override
  String get inviteFriendsEmptyState =>
      'Add friends from their profile to invite them to games.';

  @override
  String get buttonInvited => 'Invited';

  @override
  String snackInvitedFriend(String friendName) {
    return 'Invited $friendName';
  }

  @override
  String snackRevokedInvite(String friendName) {
    return 'Revoked invite for $friendName';
  }

  @override
  String get manageInviteFriends => 'Invite Friends';

  @override
  String get manageInviteFriendsSubtitle =>
      'Send an invite to your approved friends';

  @override
  String get manageEditGame => 'Edit Game';

  @override
  String get manageViewSummaryRatePlayers => 'View Summary / Rate Players';

  @override
  String get manageViewSummarySubtitle =>
      'Game is finished — open the rating flow for participants.';

  @override
  String get manageCompleteGame => 'Complete Game';

  @override
  String get manageCompleteGameSubtitle =>
      'Mark the game as finished and open ratings for participants.';

  @override
  String get manageGameAlreadyCancelled => 'Game already cancelled';

  @override
  String get manageCancelGame => 'Cancel Game';

  @override
  String get snackGameCancelled => 'Game cancelled.';

  @override
  String get dialogCancelGameTitle => 'Cancel game?';

  @override
  String get dialogCancelGameBody =>
      'This will mark the game as cancelled for all players.';

  @override
  String get dialogYesCancel => 'Yes, cancel';

  @override
  String get dialogCompleteGameTitle => 'Complete game?';

  @override
  String get dialogCompleteGameBody =>
      'This marks the game as finished, updates player stats, and unlocks rating for all approved players. This action cannot be undone.';

  @override
  String get dialogNotYet => 'Not yet';

  @override
  String get dialogMarkCompleted => 'Mark completed';

  @override
  String get snackCouldNotLoadPendingRatings =>
      'Could not load pending ratings. Pull to refresh and try again.';

  @override
  String get fallbackPlayerName => 'Player';

  @override
  String get snackEveryoneRated => 'Everyone in this game has been rated.';

  @override
  String get rateParticipantPickerTitle => 'Rate a participant';

  @override
  String get dontRateThisGame => 'Don\'t rate this game';

  @override
  String get snackWontPromptToRate =>
      'You will not be prompted to rate this game.';

  @override
  String get dialogCancelReasonTitle => 'Reason for cancellation';

  @override
  String get cancelReasonHint =>
      'e.g. Weather, venue issue, not enough players…';

  @override
  String get dialogBack => 'Back';

  @override
  String get dialogCancelGameConfirm => 'Cancel game';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get tooltipNewMessage => 'New message';

  @override
  String get failedToLoadChats => 'Failed to load chats';

  @override
  String get chatTitle => 'Chat';

  @override
  String get notParticipantInChat =>
      'You are no longer a participant in this chat.';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get messageEdited => '• edited';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get messageActionReply => 'Reply';

  @override
  String get messageActionCopyText => 'Copy text';

  @override
  String get messageActionPin => 'Pin message';

  @override
  String get messageActionUnpin => 'Unpin';

  @override
  String get messageActionDelete => 'Delete';

  @override
  String get logSessionTitle => 'Log a Session';

  @override
  String get sessionLoggedSuccess => 'Session logged! 💪';

  @override
  String get newPersonalBestTitle => '🏅 New Personal Best!';

  @override
  String get awesome => 'Awesome!';

  @override
  String get sessionType => 'Session type *';

  @override
  String get outcome => 'Outcome';

  @override
  String howDidYouPerform(int rating) {
    return 'How did you perform? $rating/5';
  }

  @override
  String get howDidYouFeel => 'How did you feel?';

  @override
  String get notes => 'Notes';

  @override
  String get saveSession => 'Save Session 💪';

  @override
  String get tooltipLogSession => 'Log a session';

  @override
  String get totalSessions => 'Total sessions';

  @override
  String get totalTime => 'Total time';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get personalBests => 'Personal Bests';

  @override
  String get bySport => 'By sport';

  @override
  String get winRateTrend => 'Win rate trend';

  @override
  String get activity => 'Activity';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get snackAlreadyRatedPlayers =>
      'You\'ve already rated the players for this game.';

  @override
  String get snackCouldNotUpdateFriendRequest =>
      'Could not update friend request';

  @override
  String get snackJoinedGame => 'You joined the game.';

  @override
  String get snackInviteDeclined => 'Invite declined.';

  @override
  String get snackActionFailed => 'Action failed.';

  @override
  String get snackInvitationNoLongerValid =>
      'This invitation is no longer valid.';

  @override
  String get snackPlayerApproved => 'Player approved.';

  @override
  String get snackJoinRequestRejected => 'Join request rejected.';

  @override
  String get buttonReject => 'Reject';

  @override
  String get emptyNotificationsTitle => 'You\'re all caught up';

  @override
  String get emptyNotificationsBody =>
      'We\'ll let you know when something new happens.';

  @override
  String get relativeTimeNow => 'now';

  @override
  String relativeTimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String relativeTimeHours(int hours) {
    return '${hours}h';
  }

  @override
  String relativeTimeDays(int days) {
    return '${days}d';
  }

  @override
  String relativeTimeWeeks(int weeks) {
    return '${weeks}w';
  }

  @override
  String get confirmReport => 'Confirm Report';

  @override
  String get continueAction => 'Continue';

  @override
  String get submitReportTitle => 'Submit Report?';

  @override
  String get goBack => 'Go Back';

  @override
  String get submit => 'Submit';

  @override
  String get reportSubmitted =>
      'Report submitted. Admins will review it shortly.';

  @override
  String get reportDetails => 'Report Details';

  @override
  String get reportTitleLabel => 'Title';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchSectionGames => 'Games';

  @override
  String get searchSectionPlayers => 'Players';

  @override
  String get ratePlayerTitle => 'Rate Player';

  @override
  String get ratingReliability => 'Reliability';

  @override
  String get ratingReliabilityHint =>
      'Did they show up on time and follow through?';

  @override
  String get ratingSportsmanship => 'Sportsmanship';

  @override
  String get ratingSportsmanshipHint =>
      'Were they fair, respectful, and fun to play with?';

  @override
  String get ratingCommentHint => 'Leave a comment (optional)...';

  @override
  String get ratingSubmitAnonymously => 'Submit anonymously';

  @override
  String get ratingAnonymousHint =>
      'Your name will not be shown to this player';

  @override
  String get buttonSubmitRating => 'Submit Rating';

  @override
  String get snackRatingSubmitted => 'Rating submitted!';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get dialogUnfriendTitle => 'Unfriend?';

  @override
  String dialogUnfriendBody(String name) {
    return 'Remove $name from your friends? You can send a new request later.';
  }

  @override
  String get buttonUnfriend => 'Unfriend';

  @override
  String snackRemovedFromFriends(String name) {
    return 'Removed $name from friends';
  }

  @override
  String get emptyNoFriendsYet =>
      'No friends yet.\nVisit someone\'s profile and tap Add Friend.';

  @override
  String get updateProfilePicture => 'Update Profile Picture';

  @override
  String get uploadFromGallery => 'Upload from gallery';

  @override
  String get choosePresetAvatar => 'Choose preset avatar';

  @override
  String get changePhotoOrAvatar => 'Change photo or avatar';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get dialogAddSportTitle => 'Add Sport';

  @override
  String get add => 'Add';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get dialogDeleteAccountTitle => 'Delete account?';

  @override
  String get dialogDeleteAccountBody =>
      'This permanently deletes your account and all data.';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get adminDashboard => 'Dashboard';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminSports => 'Sports';

  @override
  String get adminGames => 'Games';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get periodLast7Days => 'Last 7 days';

  @override
  String get periodLast30Days => 'Last 30 days';

  @override
  String get periodLast90Days => 'Last 90 days';

  @override
  String get sectionUsers => 'Users';

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get statActive30d => 'Active (30d)';

  @override
  String get statNewPeriod => 'New (period)';

  @override
  String get statBanned => 'Banned';

  @override
  String get statChurnRate => 'Churn Rate';

  @override
  String statChurnedUsersSubtitle(int count) {
    return '$count users';
  }

  @override
  String get sectionRegistrations => 'Registrations';

  @override
  String get sectionGames => 'Games';

  @override
  String get statTotalGames => 'Total Games';

  @override
  String get statActive => 'Active';

  @override
  String get statCompleted => 'Completed';

  @override
  String get statCancelled => 'Cancelled';

  @override
  String get statOngoing => 'Ongoing';

  @override
  String get statScheduled => 'Scheduled';

  @override
  String get sectionPerformance => 'Performance';

  @override
  String get statTotalLogs => 'Total Logs';

  @override
  String get sectionTopSports => 'Top Sports';

  @override
  String get globalBroadcast => 'Global Broadcast';

  @override
  String get broadcastTitleLabel => 'Title';

  @override
  String get broadcastMessageBodyLabel => 'Message body';

  @override
  String get sendToAllUsers => 'Send to All Users';

  @override
  String get snackBroadcastSent => 'Broadcast sent!';

  @override
  String get snackBroadcastFailed => 'Broadcast failed';

  @override
  String get searchUsersHint => 'Search by name, username, or email';

  @override
  String failedToLoadUsers(String error) {
    return 'Failed to load users: $error';
  }

  @override
  String failedToLoadGames(String error) {
    return 'Failed to load games: $error';
  }

  @override
  String get noGamesFoundAdmin => 'No games found';

  @override
  String get tooltipCreateEvent => 'Create event';

  @override
  String get statusAll => 'All';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusUsers => 'Users';

  @override
  String get tooltipSortByDate => 'Sort by date';

  @override
  String failedToLoadReports(String error) {
    return 'Failed to load reports: $error';
  }

  @override
  String get noReportsFound => 'No reports found';

  @override
  String adminGamesPlayedCount(int count) {
    return '$count games played';
  }

  @override
  String get adminStatusBanned => 'Banned';

  @override
  String get adminStatusRestricted => 'Restricted';

  @override
  String get adminActionUnban => 'Unban';

  @override
  String get adminActionBan => 'Ban';

  @override
  String get adminActionUnrestrict => 'Unrestrict';

  @override
  String get adminActionRestrict => 'Restrict';

  @override
  String get adminActionDelete => 'Delete';

  @override
  String get dialogDeleteUserTitle => 'Delete User';

  @override
  String get dialogDeleteUserBody => 'This cannot be undone.';

  @override
  String extraPlayersCount(int count) {
    return '+$count';
  }

  @override
  String get overviewTab => 'Overview';

  @override
  String get logsTab => 'Logs';

  @override
  String get statsTab => 'Stats';

  @override
  String get sportRequired => 'Sport *';

  @override
  String get logTypeMatch => 'Match';

  @override
  String get logTypeTraining => 'Training';

  @override
  String get logTypeFitness => 'Fitness';

  @override
  String get outcomeWin => 'Win';

  @override
  String get outcomeLoss => 'Loss';

  @override
  String get outcomeDraw => 'Draw';

  @override
  String get outcomeWinBadge => '🏆 Win';

  @override
  String get outcomeLossBadge => '❌ Loss';

  @override
  String get outcomeDrawBadge => '🤝 Draw';

  @override
  String get moodGreat => 'great';

  @override
  String get moodGood => 'good';

  @override
  String get moodOk => 'ok';

  @override
  String get moodTired => 'tired';

  @override
  String get moodInjured => 'injured';

  @override
  String get moodExcellent => 'Excellent';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodTerrible => 'Terrible';

  @override
  String durationWithMinutes(int minutes) {
    return 'Duration: ${minutes}min';
  }

  @override
  String sliderMinutesLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String get notesHint => 'What went well? What to improve?';

  @override
  String get makeLogPublic => 'Make this log public';

  @override
  String get newPersonalBestBody =>
      'You beat your previous record! Keep it up! 🎉';

  @override
  String newPersonalBestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new personal bests!',
      one: '1 new personal best!',
    );
    return '$_temp0';
  }

  @override
  String get sessionsPerWeek => 'Sessions per week';

  @override
  String chartSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get statsPreviewUnlock =>
      'Your stats preview — log sessions to unlock';

  @override
  String get warmingUp => 'Warming up';

  @override
  String get activeStreak => 'Active streak';

  @override
  String get daySingular => 'day';

  @override
  String get daysPlural => 'days';

  @override
  String get personalBest => 'Personal best';

  @override
  String get logSessionStartStreak =>
      'Log a session today to start your streak';

  @override
  String streakGoalProgress(int current, int goal) {
    return '$current of $goal-day goal · Keep it going!';
  }

  @override
  String get heatmapNoActivity => 'No activity';

  @override
  String heatmapSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get dayWed => 'Wed';

  @override
  String get dayFri => 'Fri';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get snackFriendRequestAccepted => 'Friend request accepted';

  @override
  String confirmReportBody(String targetName) {
    return 'Are you sure you want to report $targetName? False reports may result in action against your account.';
  }

  @override
  String get reportTargetThisUser => 'this user';

  @override
  String get reportTargetThisGame => 'this game';

  @override
  String submitReportBody(String title) {
    return 'Your report titled \"$title\" will be sent to admins for review.';
  }

  @override
  String get reportTitleRequired => 'Title is required';

  @override
  String get reportReasonRequired => 'Reason is required';

  @override
  String get reportUser => 'Report User';

  @override
  String get searchMinChars => 'Type at least 2 characters to search';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchNoResultsHint =>
      'Try a different sport, city, or player name';

  @override
  String get searchDiscoverTitle => 'Discover your next game';

  @override
  String get searchDiscoverSubtitle =>
      'Search by sport, city, username, or player name';

  @override
  String get searchHintNearbyGames => 'Nearby games';

  @override
  String searchPartialGamesError(String error) {
    return 'Games: $error';
  }

  @override
  String searchPartialPlayersError(String error) {
    return 'Players: $error';
  }

  @override
  String get adminNoUsersFound => 'No users found';

  @override
  String adminNoUsersMatchSearch(String query) {
    return 'No users match \"$query\".';
  }

  @override
  String adminUserCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users',
      one: '1 user',
    );
    return '$_temp0';
  }

  @override
  String failedToLoadSports(String error) {
    return 'Failed to load sports: $error';
  }

  @override
  String get adminNoSportsYet => 'No sports yet';

  @override
  String get adminSportActive => 'Active';

  @override
  String get adminSportInactive => 'Inactive';

  @override
  String get adminEdit => 'Edit';

  @override
  String get adminDeactivateSport => 'Deactivate';

  @override
  String get adminEditSport => 'Edit Sport';

  @override
  String get fieldNameLabel => 'Name';

  @override
  String get fieldIconLabel => 'Icon';

  @override
  String adminReporterLabel(String username) {
    return 'Reporter: @$username';
  }

  @override
  String adminReportedUserLabel(String username) {
    return 'Reported user: @$username';
  }

  @override
  String adminReportedGameLabel(String title) {
    return 'Reported game: $title';
  }

  @override
  String get fallbackUnknown => 'unknown';

  @override
  String get statusLabel => 'Status';

  @override
  String get adminNotesLabel => 'Admin notes';

  @override
  String get adminSearchUserPrompt =>
      'Type to find a user and manage their account.';

  @override
  String get adminNoUsersInDatabase => 'No users in the database yet.';

  @override
  String adminSearchMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String adminRecentUsersTotal(int total) {
    return 'Recent users ($total total)';
  }

  @override
  String adminViewAllResultsInUsers(int total) {
    return 'View all $total results in Users';
  }

  @override
  String get adminOpenFullUsersList => 'Open full Users list';

  @override
  String get emptyNoConversations => 'No conversations yet';

  @override
  String get emptyConversationsHint =>
      'Start a conversation by tapping the edit icon above or opening a game and tapping Chat.';

  @override
  String chatTypingSingle(String names) {
    return '$names is typing...';
  }

  @override
  String chatTypingMultiple(String names) {
    return '$names are typing...';
  }

  @override
  String replyingToName(String name) {
    return 'Replying to $name';
  }

  @override
  String chatMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get pinnedMessageLabel => 'Pinned message';

  @override
  String get emptyNoMessagesYet => 'No messages yet';

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get gameTitleHint => 'e.g. Sunday 5-a-side';

  @override
  String get gameTitleRequired => 'Title is required';

  @override
  String get gameDescriptionHint => 'Optional details, rules, what to bring…';

  @override
  String get addressHint => 'Start typing an address...';

  @override
  String get addressSelectFromSuggestions =>
      'Select a valid address from suggestions';

  @override
  String get addressVerificationFailed =>
      'Could not verify this address. Please choose another one.';

  @override
  String get pleaseSelectValidAddress =>
      'Please select a valid address from suggestions.';

  @override
  String get neighborhoodHint => 'e.g. Shoreditch';

  @override
  String get venueNameHint => 'e.g. Hackney Marshes';

  @override
  String get cityRequiredLabel => 'City *';

  @override
  String get cityHint => 'e.g. London';

  @override
  String get privateGameTitle => 'Private Game (Requires Approval)';

  @override
  String get privateGameSubtitleOn =>
      'Hidden from public search. Every join request will require your approval.';

  @override
  String get privateGameSubtitleOff =>
      'Public — anyone can find and join this game.';

  @override
  String get anySkillLevel => 'Any level';

  @override
  String get createGameButton => 'Create Game 🎮';

  @override
  String get sectionDetails => 'Details';

  @override
  String get editTitleLabel => 'Title *';

  @override
  String get optionalHint => 'Optional';

  @override
  String get sectionSchedule => 'Schedule';

  @override
  String get addressSelectedHint => 'Selected address';

  @override
  String get cityRequiredError => 'City is required.';

  @override
  String get venueShortLabel => 'Venue';

  @override
  String get calendarNoGames => 'No games';

  @override
  String calendarGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$_temp0';
  }

  @override
  String get rosterLabel => 'Roster';

  @override
  String playersCountLabel(int approved, int max) {
    return '$approved/$max players';
  }

  @override
  String distanceMetersAway(int meters) {
    return '$meters m away';
  }

  @override
  String distanceKmAway(String distance) {
    return '$distance km away';
  }

  @override
  String pendingRequestsCount(int count) {
    return '$count pending';
  }

  @override
  String get placeCouldNotResolve =>
      'Could not resolve this place. Try another.';
}
