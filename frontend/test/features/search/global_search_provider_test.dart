import 'package:buddbull/features/games/data/models/game_model.dart';
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
}
