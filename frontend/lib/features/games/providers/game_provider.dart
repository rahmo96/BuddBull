import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Simple fetch providers ────────────────────────────────────────────────────
final gameDetailProvider =
    FutureProvider.autoDispose.family<GameModel, String>((ref, id) {
  return ref.watch(gameRepositoryProvider).getGame(id);
});

final myGamesProvider =
    FutureProvider.autoDispose<List<GameModel>>((ref) {
  return ref.watch(gameRepositoryProvider).getMyGames();
});

final calendarGamesProvider =
    FutureProvider.autoDispose<List<GameModel>>((ref) {
  return ref.watch(gameRepositoryProvider).getCalendar();
});

// ── Game search state ─────────────────────────────────────────────────────────
class GameSearchState {
  const GameSearchState({
    this.games = const [],
    this.params = const GameSearchParams(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.query = '',
  });

  final List<GameModel> games;
  final GameSearchParams params;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String query;

  GameSearchState copyWith({
    List<GameModel>? games,
    GameSearchParams? params,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    String? query,
  }) {
    return GameSearchState(
      games: games ?? this.games,
      params: params ?? this.params,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
    );
  }
}

final gameSearchProvider =
    StateNotifierProvider.autoDispose<GameSearchNotifier, GameSearchState>(
  (ref) => GameSearchNotifier(ref.watch(gameRepositoryProvider)),
);

class GameSearchNotifier extends StateNotifier<GameSearchState> {
  GameSearchNotifier(this._repo) : super(const GameSearchState()) {
    search();
  }

  final GameRepository _repo;

  Future<void> search([GameSearchParams? params]) async {
    final p = params ?? state.params.copyWith(page: 1);
    state = state.copyWith(
      isLoading: true,
      params: p.copyWith(page: 1),
      clearError: true,
    );
    try {
      final games = await _repo.searchGames(p.copyWith(page: 1));
      state = state.copyWith(
        games: games,
        isLoading: false,
        hasMore: games.length >= p.limit,
        params: p.copyWith(page: 1),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.params.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await _repo.searchGames(
          state.params.copyWith(page: nextPage));
      state = state.copyWith(
        games: [...state.games, ...more],
        isLoadingMore: false,
        hasMore: more.length >= state.params.limit,
        params: state.params.copyWith(page: nextPage),
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: _msg(e));
    }
  }

  void setSport(String? sport) {
    final p = sport == null
        ? state.params.clearSport()
        : state.params.copyWith(sport: sport);
    search(p);
  }

  void setCity(String? city) => search(state.params.copyWith(city: city));

  void setSkillLevel(String? level) =>
      search(state.params.copyWith(skillLevel: level));

  void clearFilters() => search(const GameSearchParams());

  String _msg(Object e) {
    final raw = e.toString();
    final m = RegExp(r'\): (.+)$').firstMatch(raw);
    return m?.group(1) ?? raw;
  }
}

// ── Game actions (join / leave / approve / kick) ──────────────────────────────
class GameActionsState {
  const GameActionsState({
    this.isJoining = false,
    this.isLeaving = false,
    this.isProcessing = false,
    this.error,
    this.successMessage,
    this.game,
  });

  final bool isJoining;
  final bool isLeaving;
  final bool isProcessing;
  final String? error;
  final String? successMessage;
  final GameModel? game;

  GameActionsState copyWith({
    bool? isJoining,
    bool? isLeaving,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    GameModel? game,
  }) {
    return GameActionsState(
      isJoining: isJoining ?? this.isJoining,
      isLeaving: isLeaving ?? this.isLeaving,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : error ?? this.error,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      game: game ?? this.game,
    );
  }
}

final gameActionsProvider = StateNotifierProvider.autoDispose
    .family<GameActionsNotifier, GameActionsState, String>(
  (ref, gameId) =>
      GameActionsNotifier(ref.watch(gameRepositoryProvider), ref, gameId),
);

class GameActionsNotifier extends StateNotifier<GameActionsState> {
  GameActionsNotifier(this._repo, this._ref, this._gameId)
      : super(const GameActionsState());

  final GameRepository _repo;
  final Ref _ref;
  final String _gameId;

  Future<void> join() async {
    state = state.copyWith(isJoining: true, clearError: true);
    try {
      final game = await _repo.joinGame(_gameId);
      state = state.copyWith(
        isJoining: false,
        game: game,
        successMessage: 'Join request sent!',
      );
      _ref.invalidate(gameDetailProvider(_gameId));
    } catch (e) {
      state = state.copyWith(isJoining: false, error: _msg(e));
    }
  }

  Future<void> leave() async {
    state = state.copyWith(isLeaving: true, clearError: true);
    try {
      final game = await _repo.leaveGame(_gameId);
      state = state.copyWith(
        isLeaving: false,
        game: game,
        successMessage: 'You left the game.',
      );
      _ref.invalidate(gameDetailProvider(_gameId));
    } catch (e) {
      state = state.copyWith(isLeaving: false, error: _msg(e));
    }
  }

  Future<void> approvePlayer(String userId) async {
    state = state.copyWith(isProcessing: true);
    try {
      final game = await _repo.approvePlayer(_gameId, userId);
      state = state.copyWith(isProcessing: false, game: game);
      _ref.invalidate(gameDetailProvider(_gameId));
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: _msg(e));
    }
  }

  Future<void> kickPlayer(String userId) async {
    state = state.copyWith(isProcessing: true);
    try {
      final game = await _repo.kickPlayer(_gameId, userId);
      state = state.copyWith(isProcessing: false, game: game);
      _ref.invalidate(gameDetailProvider(_gameId));
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: _msg(e));
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  String _msg(Object e) {
    final raw = e.toString();
    final m = RegExp(r'\): (.+)$').firstMatch(raw);
    return m?.group(1) ?? raw;
  }
}

// ── Create game state ─────────────────────────────────────────────────────────
class CreateGameState {
  const CreateGameState({
    this.isSubmitting = false,
    this.error,
    this.createdGame,
  });

  final bool isSubmitting;
  final String? error;
  final GameModel? createdGame;

  CreateGameState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    GameModel? createdGame,
  }) {
    return CreateGameState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      createdGame: createdGame ?? this.createdGame,
    );
  }
}

final createGameProvider =
    StateNotifierProvider.autoDispose<CreateGameNotifier, CreateGameState>(
  (ref) => CreateGameNotifier(ref.watch(gameRepositoryProvider), ref),
);

class CreateGameNotifier extends StateNotifier<CreateGameState> {
  CreateGameNotifier(this._repo, this._ref)
      : super(const CreateGameState());

  final GameRepository _repo;
  final Ref _ref;

  Future<bool> createGame(Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final game = await _repo.createGame(payload);
      state = state.copyWith(isSubmitting: false, createdGame: game);
      _ref.invalidate(myGamesProvider);
      _ref.invalidate(calendarGamesProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _msg(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _msg(Object e) {
    final raw = e.toString();
    final m = RegExp(r'\): (.+)$').firstMatch(raw);
    return m?.group(1) ?? raw;
  }
}
