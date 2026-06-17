import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/profile/data/user_repository.dart';
import 'package:buddbull/features/search/providers/global_search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlobalSearchState', () {
    test('isEmpty when searched with no results', () {
      const state = GlobalSearchState(
        query: 'test',
        hasSearched: true,
        isLoading: false,
      );
      expect(state.isEmpty, isTrue);
    });

    test('hasPartialFailure when one section errors', () {
      const state = GlobalSearchState(
        query: 'football',
        games: [],
        users: [],
        gamesError: 'Server error',
        hasSearched: true,
      );
      expect(state.hasPartialFailure, isTrue);
    });
  });

  group('GameSearchParams', () {
    test('includes q in query params', () {
      const params = GameSearchParams(q: 'tennis', limit: 8);
      expect(params.toQueryParams()['q'], 'tennis');
      expect(params.toQueryParams()['limit'], 8);
    });
  });

  group('GlobalSearchNotifier', () {
    late _FakeGameRepository gameRepo;
    late _FakeUserRepository userRepo;
    late GlobalSearchNotifier notifier;

    setUp(() {
      final api = ApiClient();
      gameRepo = _FakeGameRepository(api);
      userRepo = _FakeUserRepository(api);
      notifier = GlobalSearchNotifier(gameRepo, userRepo);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('clearing the query resets search state', () {
      notifier.setQuery('ab');
      notifier.clear();

      expect(notifier.state, const GlobalSearchState());
    });

    test('queries shorter than two characters do not search', () {
      notifier.setQuery('a');
      expect(notifier.state.hasSearched, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(gameRepo.searchCalls, isEmpty);
      expect(userRepo.searchCalls, isEmpty);
    });

    test('debounced search merges games and users', () async {
      gameRepo.results = [
        GameModel.fromJson({
          '_id': 'g-1',
          'title': 'Sunday Football',
          'sport': 'football',
          'scheduledAt': DateTime(2026, 6, 1).toUtc().toIso8601String(),
          'durationMinutes': 90,
          'location': {'city': 'London'},
          'maxPlayers': 10,
          'status': 'open',
        }),
      ];
      userRepo.results = [
        UserModel.fromJson({
          '_id': 'u-1',
          'firstName': 'Alex',
          'lastName': 'Rivera',
          'username': 'alexriver',
          'email': 'alex@example.com',
        }),
      ];

      notifier.setQuery('alex');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.games, hasLength(1));
      expect(notifier.state.users, hasLength(1));
      expect(notifier.state.error, isNull);
      expect(gameRepo.searchCalls.single.q, 'alex');
      expect(userRepo.searchCalls.single, 'alex');
    });

    test('falls back to city search when q search fails', () async {
      gameRepo.failFirstSearch = true;

      notifier.setQuery('london');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(gameRepo.searchCalls, hasLength(2));
      expect(gameRepo.searchCalls.first.q, 'london');
      expect(gameRepo.searchCalls.last.city, 'london');
    });

    test('records partial failure when one section returns empty with an error',
        () async {
      gameRepo.error = 'Games unavailable';

      notifier.setQuery('football');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(notifier.state.hasPartialFailure, isTrue);
      expect(notifier.state.gamesError, contains('Games unavailable'));
    });
  });
}

class _FakeGameRepository extends GameRepository {
  _FakeGameRepository(super.api);

  final List<GameSearchParams> searchCalls = [];
  List<GameModel> results = const [];
  String? error;
  bool failFirstSearch = false;

  @override
  Future<List<GameModel>> searchGames(GameSearchParams params) async {
    searchCalls.add(params);
    if (failFirstSearch && searchCalls.length == 1) {
      throw Exception('primary search failed');
    }
    if (error != null) {
      throw Exception(error);
    }
    return results;
  }
}

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository(super.api);

  final List<String> searchCalls = [];
  List<UserModel> results = const [];

  @override
  Future<List<UserModel>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    searchCalls.add(query);
    return results;
  }
}
