import 'dart:async';

import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/profile/data/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Global search state ───────────────────────────────────────────────────────
class GlobalSearchState {
  const GlobalSearchState({
    this.query = '',
    this.games = const [],
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.gamesError,
    this.usersError,
    this.hasSearched = false,
  });

  final String query;
  final List<GameModel> games;
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final String? gamesError;
  final String? usersError;
  final bool hasSearched;

  bool get isEmpty =>
      hasSearched && !isLoading && games.isEmpty && users.isEmpty;

  bool get hasPartialFailure =>
      (gamesError != null && games.isEmpty) ||
      (usersError != null && users.isEmpty);

  GlobalSearchState copyWith({
    String? query,
    List<GameModel>? games,
    List<UserModel>? users,
    bool? isLoading,
    String? error,
    String? gamesError,
    String? usersError,
    bool? hasSearched,
    bool clearError = false,
    bool clearGamesError = false,
    bool clearUsersError = false,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      games: games ?? this.games,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      gamesError: clearGamesError ? null : (gamesError ?? this.gamesError),
      usersError: clearUsersError ? null : (usersError ?? this.usersError),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

final globalSearchProvider =
    StateNotifierProvider.autoDispose<GlobalSearchNotifier, GlobalSearchState>(
  (ref) => GlobalSearchNotifier(
    ref.watch(gameRepositoryProvider),
    ref.watch(userRepositoryProvider),
  ),
);

class GlobalSearchNotifier extends StateNotifier<GlobalSearchState> {
  GlobalSearchNotifier(this._gameRepo, this._userRepo)
      : super(const GlobalSearchState());

  final GameRepository _gameRepo;
  final UserRepository _userRepo;
  Timer? _debounce;
  int _searchGeneration = 0;

  void setQuery(String query) {
    final trimmed = query.trim();
    state = state.copyWith(
      query: query,
      clearError: true,
      clearGamesError: true,
      clearUsersError: true,
    );

    _debounce?.cancel();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        games: const [],
        users: const [],
        isLoading: false,
        hasSearched: false,
        clearError: true,
        clearGamesError: true,
        clearUsersError: true,
      );
      return;
    }

    if (trimmed.length < 2) {
      state = state.copyWith(
        games: const [],
        users: const [],
        isLoading: false,
        hasSearched: false,
        clearError: true,
        clearGamesError: true,
        clearUsersError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, hasSearched: true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;

    List<GameModel> games = const [];
    List<UserModel> users = const [];
    String? gamesError;
    String? usersError;

    await Future.wait<void>([
      () async {
        try {
          games = await _searchGames(query);
        } catch (e) {
          gamesError = _msg(e);
        }
      }(),
      () async {
        try {
          users = await _searchUsers(query);
        } catch (e) {
          usersError = _msg(e);
        }
      }(),
    ]);

    if (generation != _searchGeneration || state.query.trim() != query) return;

    final hasResults = games.isNotEmpty || users.isNotEmpty;
    final combinedError = hasResults
        ? null
        : gamesError ?? usersError ?? 'No results found';

    state = state.copyWith(
      games: games,
      users: users,
      isLoading: false,
      error: combinedError,
      gamesError: gamesError,
      usersError: usersError,
      clearError: combinedError == null,
    );
  }

  Future<List<GameModel>> _searchGames(String query) async {
    try {
      return await _gameRepo.searchGames(
        GameSearchParams(q: query, limit: 8),
      );
    } catch (_) {
      return _gameRepo.searchGames(
        GameSearchParams(city: query, limit: 8),
      );
    }
  }

  Future<List<UserModel>> _searchUsers(String query) =>
      _userRepo.searchUsers(query: query, limit: 8);

  void clear() {
    _debounce?.cancel();
    _searchGeneration++;
    state = const GlobalSearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _msg(Object e) {
    final raw = e.toString();
    final m = RegExp(r'\): (.+)$').firstMatch(raw);
    return m?.group(1) ?? raw;
  }
}
