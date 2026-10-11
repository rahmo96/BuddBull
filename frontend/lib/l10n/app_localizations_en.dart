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

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonBrowseAll => 'Browse all';

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
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String homeGreetingNoName(String greeting) {
    return '$greeting!';
  }

  @override
  String get homeStatGames => 'Games';

  @override
  String get homeStatRating => 'Rating';

  @override
  String get homeStatStreak => 'Streak';

  @override
  String homeStreakDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get homeMyUpcomingGames => 'My Upcoming Games';

  @override
  String get homeExploreNearYou => 'Explore Near You';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeFindGame => 'Find a Game';

  @override
  String get homeLogSession => 'Log Session';

  @override
  String get homeCreateGame => 'Create Game';

  @override
  String get homeRecentActivity => 'Recent Activity';

  @override
  String get homeNoRecentSessions => 'No recent sessions';

  @override
  String get homeLogASession => 'Log a session';

  @override
  String get homeNoUpcomingGames => 'No upcoming games';

  @override
  String get homeBrowseGames => 'Browse games';

  @override
  String get homeNearbyLoadFailed => 'Couldn\'t load nearby games';

  @override
  String get homeNothingNearby => 'Nothing nearby right now';

  @override
  String get homeTagline => 'Find your squad. Play your game.';

  @override
  String get homeNotificationsTooltip => 'Notifications';

  @override
  String get homeMyCalendarTooltip => 'My calendar';

  @override
  String get homeAddGame => 'Add Game';

  @override
  String get homeLogTraining => 'Log Training';

  @override
  String get searchHint => 'Search games, players…';

  @override
  String get searchCloseTooltip => 'Close search';

  @override
  String get searchMinChars => 'Type at least 2 characters to search';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchNoResultsHint =>
      'Try a different sport, city, or player name';

  @override
  String get searchSectionGames => 'Games';

  @override
  String get searchSectionPlayers => 'Players';

  @override
  String searchGamesError(String error) {
    return 'Games: $error';
  }

  @override
  String searchPlayersError(String error) {
    return 'Players: $error';
  }

  @override
  String get searchChipNearby => 'Nearby games';

  @override
  String get searchDiscoverTitle => 'Discover your next game';

  @override
  String get searchDiscoverSubtitle =>
      'Search by sport, city, username, or player name';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportVolleyball => 'Volleyball';

  @override
  String get sportRunning => 'Running';

  @override
  String get sportSwimming => 'Swimming';

  @override
  String get sportCycling => 'Cycling';

  @override
  String get sportCricket => 'Cricket';

  @override
  String get commonAll => 'All';

  @override
  String get commonClear => 'Clear';

  @override
  String get gamesCreateTooltip => 'Create game';

  @override
  String get gamesSearchHint => 'Search games, sports, locations…';

  @override
  String get gamesFilterTooltip => 'Filter';

  @override
  String gamesFiltersActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters active',
      one: '1 filter active',
    );
    return '$_temp0';
  }

  @override
  String get gamesNoneFound => 'No games found';

  @override
  String get gamesNoneFoundHint =>
      'Try adjusting your filters or create a new game.';

  @override
  String get gamesCreateAGame => 'Create a game';

  @override
  String get skillAnyLevel => 'Any level';

  @override
  String get commonClearAll => 'Clear all';

  @override
  String get commonSport => 'Sport';

  @override
  String get gamesFilterTitle => 'Filter Games';

  @override
  String get gamesFilterNearMe => 'Near me';

  @override
  String get gamesFilterNearMeHint =>
      'Show games closest to your current location';

  @override
  String get gamesFilterCityHint => 'e.g. London';

  @override
  String get gamesFilterSkillTitle => 'Required skill level';

  @override
  String get gamesFilterGettingLocation => 'Getting location…';

  @override
  String get gamesFilterApply => 'Apply Filters';

  @override
  String gamesPlayersOf(int current, int max) {
    return '$current/$max players';
  }

  @override
  String gamesPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get gamesJoinGame => 'Join Game';

  @override
  String get gamesRoster => 'Roster';

  @override
  String get gamesStatusOpen => 'Open';

  @override
  String get gamesStatusFull => 'Full';

  @override
  String get gamesStatusLive => 'Live';

  @override
  String get gamesStatusDone => 'Done';

  @override
  String get gamesStatusCancelled => 'Cancelled';

  @override
  String get gamesFullBadge => 'FULL';

  @override
  String gamesDistanceMeters(int meters) {
    return '$meters m away';
  }

  @override
  String gamesDistanceKm(String km) {
    return '$km km away';
  }

  @override
  String get calendarTitle => 'My Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarNoGamesOnDay => 'No games on this day';

  @override
  String get calendarFormatMonth => 'Month';

  @override
  String get calendarFormatTwoWeeks => '2 weeks';

  @override
  String get calendarFormatWeek => 'Week';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
      zero: 'No games',
    );
    return '$_temp0';
  }

  @override
  String get commonLocationPermissionDenied =>
      'Location access is needed to find games near you. Enable it in settings or use city search.';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonSaveChanges => 'Save Changes';

  @override
  String get gameCreateTitle => 'Create Game';

  @override
  String get gameCreateButton => 'Create Game 🎮';

  @override
  String get gameCreateSuccess => 'Game created! 🎉';

  @override
  String get gameEditTitle => 'Edit Game';

  @override
  String get gameEditUpdated => 'Game updated.';

  @override
  String get gameFormSportLabel => 'Sport *';

  @override
  String get gameFormTitleLabel => 'Game title *';

  @override
  String get gameFormTitleHint => 'e.g. Sunday 5-a-side';

  @override
  String get gameFormTitleRequired => 'Title is required';

  @override
  String get gameFormDescriptionLabel => 'Description';

  @override
  String get gameFormDescriptionHint =>
      'Optional details, rules, what to bring…';

  @override
  String get gameFormDateTime => 'Date & Time *';

  @override
  String gameFormDuration(int hours, String minutes) {
    return 'Duration: ${hours}h ${minutes}m';
  }

  @override
  String gameFormDurationSlider(int minutes) {
    return '${minutes}min';
  }

  @override
  String get gameFormLocationRequired => 'Location *';

  @override
  String get gameFormAddressLabel => 'Address *';

  @override
  String get gameFormAddressHint => 'Start typing an address...';

  @override
  String get gameFormAddressInvalid =>
      'Select a valid address from suggestions';

  @override
  String get gameFormAddressNotVerified =>
      'Could not verify this address. Please choose another one.';

  @override
  String get gameFormAddressSelectFromList =>
      'Please select a valid address from suggestions.';

  @override
  String get gameFormNeighborhoodHint => 'e.g. Shoreditch';

  @override
  String get gameFormVenueLabel => 'Venue name';

  @override
  String get gameFormVenueHint => 'e.g. Hackney Marshes';

  @override
  String get gameFormCityLabel => 'City *';

  @override
  String get gameFormCityHint => 'e.g. London';

  @override
  String gameFormMaxPlayers(int count) {
    return 'Max players: $count';
  }

  @override
  String get gameFormVisibility => 'Visibility';

  @override
  String get gameFormPrivateTitle => 'Private Game (Requires Approval)';

  @override
  String get gameFormPrivateHint =>
      'Hidden from public search. Every join request will require your approval.';

  @override
  String get gameFormPublicHint =>
      'Public — anyone can find and join this game.';

  @override
  String get gameFormDetails => 'Details';

  @override
  String get gameFormSchedule => 'Schedule';

  @override
  String get gameFormLocation => 'Location';

  @override
  String get gameEditTitleLabel => 'Title *';

  @override
  String get gameEditTitleHint => 'Game title';

  @override
  String get gameEditTitleRequired => 'Title is required.';

  @override
  String gameEditDuration(int minutes) {
    return 'Duration: ${minutes}min';
  }

  @override
  String gameEditSliderMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get gameEditAddressLabel => 'Address';

  @override
  String get gameEditAddressHint => 'Selected address';

  @override
  String get gameEditCityHint => 'City';

  @override
  String get gameEditCityRequired => 'City is required.';

  @override
  String get gameEditNeighborhoodLabel => 'Neighborhood';

  @override
  String get gameEditVenueLabel => 'Venue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNo => 'No';

  @override
  String get gamesStatusCompleted => 'Completed';

  @override
  String gameDurationMin(Object minutes) {
    return '${minutes}min';
  }

  @override
  String gameDurationHr(Object hours) {
    return '${hours}h';
  }

  @override
  String gameDurationHrMin(Object hours, Object minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String get gameDetailRequestDeclined =>
      'Your request to join was declined. You can try again below.';

  @override
  String get gameDetailDate => 'Date';

  @override
  String get gameDetailTime => 'Time';

  @override
  String get gameDetailDuration => 'Duration';

  @override
  String get gameDetailAbout => 'About this game';

  @override
  String get gameDetailOrganiser => 'Organiser';

  @override
  String get gameDetailPlayers => 'Players';

  @override
  String get gameDetailResult => 'Match Result';

  @override
  String get gameDetailTags => 'Tags';

  @override
  String get gameDetailReport => 'Report Game';

  @override
  String get gameDetailMapUnavailable => 'Map preview unavailable';

  @override
  String get gameDetailApproved => 'Approved';

  @override
  String get gameDetailPendingRequests => 'Pending requests';

  @override
  String get gameDetailRate => 'Rate';

  @override
  String get gameDetailApprove => 'Approve';

  @override
  String get gameDetailKick => 'Kick';

  @override
  String get gameDetailRatePrompt =>
      'Rate participants below to share how the game went.';

  @override
  String get gameDetailChat => 'Chat';

  @override
  String get gameDetailRateParticipants => 'Rate Participants';

  @override
  String get gameDetailGameCompleted => 'Game Completed';

  @override
  String get gameDetailManage => 'Manage (Organiser)';

  @override
  String get gameDetailGameFull => 'Game is Full';

  @override
  String get gameDetailRequestToJoin => 'Request to Join';

  @override
  String get gameDetailLeave => 'Leave Game';

  @override
  String get gameDetailInvitedBanner => 'You\'re invited to this game';

  @override
  String get gameDetailAcceptInvite => 'Accept Invitation';

  @override
  String get gameDetailDecline => 'Decline';

  @override
  String get gameDetailPendingBanner => 'Your request is pending approval';

  @override
  String get gameDetailWithdraw => 'Withdraw';

  @override
  String get gameDetailInviteFriends => 'Invite Friends';

  @override
  String get gameDetailNoFriends =>
      'Add friends from their profile to invite them to games.';

  @override
  String get gameDetailInvitedChip => 'Invited';

  @override
  String get gameDetailMergeTitle => 'Merge game?';

  @override
  String get gameDetailMergeButton => 'Merge';

  @override
  String get gameDetailCapacityTitle => 'Increase capacity?';

  @override
  String get gameDetailCapacityBody =>
      'The target game is too full for this merge. Expand its capacity and complete the merge?';

  @override
  String get gameDetailForceMerge => 'Force merge';

  @override
  String get gameDetailMergeSuccess => 'Game merged successfully.';

  @override
  String get gameDetailMergeSheetTitle => 'Merge Game';

  @override
  String get gameDetailMergeNone => 'No eligible open games found.';

  @override
  String get gameDetailInviteFriendsHint =>
      'Send an invite to your approved friends';

  @override
  String get gameDetailMergeHint => 'Combine this game into another open game';

  @override
  String get gameDetailViewSummary => 'View Summary / Rate Players';

  @override
  String get gameDetailViewSummaryHint =>
      'Game is finished — open the rating flow for participants.';

  @override
  String get gameDetailCompleteGame => 'Complete Game';

  @override
  String get gameDetailCompleteGameHint =>
      'Mark the game as finished and open ratings for participants.';

  @override
  String get gameDetailAlreadyCancelled => 'Game already cancelled';

  @override
  String get gameDetailCancelGame => 'Cancel Game';

  @override
  String get gameDetailCancelled => 'Game cancelled.';

  @override
  String get gameDetailCancelConfirmTitle => 'Cancel game?';

  @override
  String get gameDetailCancelConfirmBody =>
      'This will mark the game as cancelled for all players.';

  @override
  String get gameDetailYesCancel => 'Yes, cancel';

  @override
  String get gameDetailCompleteConfirmTitle => 'Complete game?';

  @override
  String get gameDetailCompleteConfirmBody =>
      'This marks the game as finished, updates player stats, and unlocks rating for all approved players. This action cannot be undone.';

  @override
  String get gameDetailNotYet => 'Not yet';

  @override
  String get gameDetailMarkCompleted => 'Mark completed';

  @override
  String get gameDetailPendingRatingsFailed =>
      'Could not load pending ratings. Pull to refresh and try again.';

  @override
  String get gameDetailPlayerFallback => 'Player';

  @override
  String get gameDetailAllRated => 'Everyone in this game has been rated.';

  @override
  String get gameDetailRateAParticipant => 'Rate a participant';

  @override
  String get gameDetailWontRatePrompt =>
      'You will not be prompted to rate this game.';

  @override
  String get gameDetailDontRate => 'Don\'t rate this game';

  @override
  String get gameDetailCancelReasonTitle => 'Reason for cancellation';

  @override
  String get gameDetailCancelReasonHint =>
      'e.g. Weather, venue issue, not enough players…';

  @override
  String get gameDetailCancelGameButton => 'Cancel game';

  @override
  String gameDetailPlayerYou(String name) {
    return '$name (You)';
  }

  @override
  String gameDetailScore(String score) {
    return 'Score: $score';
  }

  @override
  String gameDetailWinner(String winner) {
    return 'Winner: $winner';
  }

  @override
  String gameDetailInvitedName(String name) {
    return 'Invited $name';
  }

  @override
  String gameDetailRevokedName(String name) {
    return 'Revoked invite for $name';
  }

  @override
  String gameDetailMergeConfirmBody(String source, String target) {
    return 'Merge \'$source\' into \'$target\'?\nYour game will be cancelled and players moved to the target.';
  }

  @override
  String gameDetailMergePick(String sport, String city) {
    return 'Pick an open $sport game in $city.';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonApprove => 'Approve';

  @override
  String get commonReject => 'Reject';

  @override
  String get chatTitleFallback => 'Chat';

  @override
  String get chatNewMessage => 'New message';

  @override
  String get chatLoadFailed => 'Failed to load chats';

  @override
  String get chatNoConversations => 'No conversations yet';

  @override
  String get chatNoConversationsHint =>
      'Start a conversation by tapping the edit icon above or opening a game and tapping Chat.';

  @override
  String get chatNoLongerParticipant =>
      'You are no longer a participant in this chat.';

  @override
  String get chatMessageHint => 'Type a message...';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatEdited => '• edited';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatPinMessage => 'Pin message';

  @override
  String get chatPinnedMessage => 'Pinned message';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsAllCaughtUp => 'You\'re all caught up';

  @override
  String get notificationsAllCaughtUpHint =>
      'We\'ll let you know when something new happens.';

  @override
  String get notificationsAlreadyRated =>
      'You\'ve already rated the players for this game.';

  @override
  String get notificationsFriendAccepted => 'Friend request accepted';

  @override
  String get notificationsFriendDeclined => 'Friend request declined';

  @override
  String get notificationsFriendUpdateFailed =>
      'Could not update friend request';

  @override
  String get notificationsJoinedGame => 'You joined the game.';

  @override
  String get notificationsInviteDeclined => 'Invite declined.';

  @override
  String get notificationsActionFailed => 'Action failed.';

  @override
  String get notificationsInviteInvalid =>
      'This invitation is no longer valid.';

  @override
  String get notificationsPlayerApproved => 'Player approved.';

  @override
  String get notificationsJoinRejected => 'Join request rejected.';

  @override
  String get notificationsRelNow => 'now';

  @override
  String chatMembersCount(int count) {
    return '$count members';
  }

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String notificationsRelMinutes(int count) {
    return '${count}m';
  }

  @override
  String notificationsRelHours(int count) {
    return '${count}h';
  }

  @override
  String notificationsRelDays(int count) {
    return '${count}d';
  }

  @override
  String notificationsRelWeeks(int count) {
    return '${count}w';
  }

  @override
  String chatTypingOne(String names) {
    return '$names is typing...';
  }

  @override
  String chatTypingMany(String names) {
    return '$names are typing...';
  }

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonLocation => 'Location';

  @override
  String commonMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileBioHint => 'Tell us a bit about yourself…';

  @override
  String get profileSportsInterests => 'Sports & Skill Levels';

  @override
  String get profileAddSport => '+ Add sport';

  @override
  String get profileRadiusLabel => 'Search radius (km)';

  @override
  String get profileUpdatePicture => 'Update Profile Picture';

  @override
  String get profileUploadGallery => 'Upload from gallery';

  @override
  String get profileChoosePreset => 'Choose preset avatar';

  @override
  String get profileChangePhoto => 'Change photo or avatar';

  @override
  String get profilePersonalInfo => 'Personal Info';

  @override
  String get profileCityHint => 'Start typing a city…';

  @override
  String get profileAreaHint => 'Start typing an area or street…';

  @override
  String get profileAddSportTitle => 'Add Sport';

  @override
  String get profileSkillLevel => 'Skill Level';

  @override
  String get profileDangerZone => 'Danger Zone';

  @override
  String get profileDeleteWarning =>
      'Deleting your account is permanent and cannot be undone.';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteConfirmTitle => 'Delete account?';

  @override
  String get profileDeleteConfirmBody =>
      'All your data will be permanently deleted. This action cannot be undone.';

  @override
  String get profileDeletePermanently => 'Delete permanently';

  @override
  String get profileFriends => 'Friends';

  @override
  String get friendsUnfriendTitle => 'Unfriend?';

  @override
  String get friendsUnfriend => 'Unfriend';

  @override
  String get friendsEmpty =>
      'No friends yet.\nVisit someone\'s profile and tap Add Friend.';

  @override
  String get profileAdminDashboard => 'Admin Dashboard';

  @override
  String get profileEditTooltip => 'Edit profile';

  @override
  String get profileSignOutTooltip => 'Sign out';

  @override
  String get profileAbout => 'About';

  @override
  String get profileSports => 'Sports';

  @override
  String get profileRecentActivity => 'Recent Activity';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutBody => 'You will need to sign in again.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileWinRate => 'Win Rate %';

  @override
  String get profileRatingsSummary => 'Ratings Summary';

  @override
  String get profileRatingOverall => 'Overall';

  @override
  String get profileRatingReliability => 'Reliability';

  @override
  String get profileRatingBehavior => 'Behavior';

  @override
  String get profileUpcomingGames => 'Upcoming Games';

  @override
  String get profileNoRatings => 'No ratings yet';

  @override
  String get profileFriendRequestSent => 'Friend request sent';

  @override
  String get profileNowFriends => 'You are now friends';

  @override
  String get profileSignInToMessage => 'Please sign in to send a message.';

  @override
  String get profileCannotMessageSelf => 'You cannot message yourself.';

  @override
  String get profileMessage => 'Message';

  @override
  String get profileRequestSent => 'Request sent';

  @override
  String get profileAddFriend => 'Add Friend';

  @override
  String get profilePlaceResolveFailed =>
      'Could not resolve this place. Try another.';

  @override
  String get profileSelectCityFirst => 'Please select a city first';

  @override
  String friendsUnfriendBody(String name) {
    return 'Remove $name from your friends? You can send a new request later.';
  }

  @override
  String friendsRemoved(String name) {
    return 'Removed $name from friends';
  }

  @override
  String profileMutualConnections(int count) {
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
  String profileRadiusKmBadge(int km) {
    return '$km km radius';
  }

  @override
  String profileRadiusKmValue(int km) {
    return '$km km';
  }

  @override
  String profileCommunityAverageOne(String avg) {
    return 'Community average $avg from 1 peer rating';
  }

  @override
  String profileCommunityAverageMany(String avg, int count) {
    return 'Community average $avg from $count peer ratings';
  }

  @override
  String profileFriendsCount(int count) {
    return '$count Friends';
  }

  @override
  String profileRatingWithCount(int count) {
    return 'Rating ($count)';
  }

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
  String get moodGreat => 'Great';

  @override
  String get moodGood => 'Good';

  @override
  String get moodOk => 'OK';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodInjured => 'Injured';

  @override
  String get logFormSessionLogged => 'Session logged! 💪';

  @override
  String get logFormPersonalBestTitle => '🏅 New Personal Best!';

  @override
  String get logFormPersonalBestBody =>
      'You beat your previous record! Keep it up! 🎉';

  @override
  String get logFormAwesome => 'Awesome!';

  @override
  String get logFormTitle => 'Log a Session';

  @override
  String get logFormSessionType => 'Session type *';

  @override
  String get logFormOutcome => 'Outcome';

  @override
  String get logFormDuration => 'Duration';

  @override
  String get logFormFeel => 'How did you feel?';

  @override
  String get logFormNotes => 'Notes';

  @override
  String get logFormNotesHint => 'What went well? What to improve?';

  @override
  String get logFormPublic => 'Make this log public';

  @override
  String get logFormSave => 'Save Session 💪';

  @override
  String get performanceTotalSessions => 'Total sessions';

  @override
  String get performanceTotalTime => 'Total time';

  @override
  String get performanceNoSessions => 'No sessions yet';

  @override
  String get performanceNoSessionsHint =>
      'Start logging your training and matches.';

  @override
  String get performancePersonalBests => 'Personal Bests';

  @override
  String get performanceBySport => 'By sport';

  @override
  String get performanceBuildStats => 'Log sessions to build your stats';

  @override
  String get performanceTabOverview => 'Overview';

  @override
  String get performanceTabLogs => 'Logs';

  @override
  String get performanceTabStats => 'Stats';

  @override
  String get heatmapActivity => 'Activity';

  @override
  String get heatmapNoActivity => 'No activity';

  @override
  String get heatmapOneSession => '1 session';

  @override
  String get heatmapLess => 'Less';

  @override
  String get heatmapMore => 'More';

  @override
  String get logCardOnePersonalBest => '1 new personal best!';

  @override
  String get progressSessionsPerWeek => 'Sessions per week';

  @override
  String get progressWinRateTrend => 'Win rate trend';

  @override
  String get progressPreview => 'Your stats preview — log sessions to unlock';

  @override
  String get streakWarmingUp => 'Warming up';

  @override
  String get streakActive => 'Active streak';

  @override
  String get streakPersonalBest => 'Personal best';

  @override
  String get streakDaySingular => 'day';

  @override
  String get streakDayPlural => 'days';

  @override
  String get streakStartToday => 'Log a session today to start your streak';

  @override
  String get rateTitle => 'Rate Player';

  @override
  String get rateSportsmanship => 'Sportsmanship';

  @override
  String get rateSportsmanshipHint =>
      'Were they fair, respectful, and fun to play with?';

  @override
  String get rateReliabilityHint =>
      'Did they show up on time and follow through?';

  @override
  String get rateCommentHint => 'Leave a comment (optional)...';

  @override
  String get rateAnonymous => 'Submit anonymously';

  @override
  String get rateAnonymousHint => 'Your name will not be shown to this player';

  @override
  String get rateSubmit => 'Submit Rating';

  @override
  String get rateSubmitted => 'Rating submitted!';

  @override
  String get reportTargetUser => 'this user';

  @override
  String get reportTargetGame => 'this game';

  @override
  String get reportConfirmTitle => 'Confirm Report';

  @override
  String get reportContinue => 'Continue';

  @override
  String get reportSubmitTitle => 'Submit Report?';

  @override
  String get reportGoBack => 'Go Back';

  @override
  String get reportSubmit => 'Submit';

  @override
  String get reportSubmitted =>
      'Report submitted. Admins will review it shortly.';

  @override
  String get reportDetails => 'Report Details';

  @override
  String get reportFormTitle => 'Title';

  @override
  String get reportFormTitleRequired => 'Title is required';

  @override
  String get reportFormReason => 'Reason';

  @override
  String get reportFormReasonRequired => 'Reason is required';

  @override
  String get reportUser => 'Report User';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsPush => 'Push Notifications';

  @override
  String get settingsPushHint => 'Receive notifications about activities';

  @override
  String get settingsReminders => 'Activity Reminders';

  @override
  String get settingsRemindersHint => 'Remind me before scheduled activities';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeHint => 'Use dark theme';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsNotificationsOn => 'Notifications enabled';

  @override
  String get settingsNotificationsOff => 'Notifications disabled';

  @override
  String get settingsDarkOn => 'Dark mode on';

  @override
  String get settingsDarkOff => 'Dark mode off';

  @override
  String get settingsRemindersOn => 'Activity reminders on';

  @override
  String get settingsRemindersOff => 'Activity reminders off';

  @override
  String logFormDurationWithValue(int minutes) {
    return 'Duration: ${minutes}min';
  }

  @override
  String logFormSelfRating(int rating) {
    return 'How did you perform? $rating/5';
  }

  @override
  String performanceTotalTimeHrMin(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String heatmapSessions(int count) {
    return '$count sessions';
  }

  @override
  String logCardPersonalBests(int count) {
    return '$count new personal bests!';
  }

  @override
  String progressTooltip(int sessions, int minutes) {
    return '$sessions sessions\n$minutes min';
  }

  @override
  String streakGoalProgress(int current, int goal) {
    return '$current of $goal-day goal · Keep it going!';
  }

  @override
  String streakLongestDays(int count) {
    return '$count d';
  }

  @override
  String reportConfirmBody(String target) {
    return 'Are you sure you want to report $target? False reports may result in action against your account.';
  }

  @override
  String reportSubmitBody(String title) {
    return 'Your report titled \"$title\" will be sent to admins for review.';
  }
}
