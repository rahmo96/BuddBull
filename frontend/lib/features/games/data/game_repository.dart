import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(ref.watch(apiClientProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────
class GameRepository {
  const GameRepository(this._api);
  final ApiClient _api;

  // ── Search ────────────────────────────────────────────────
  Future<List<GameModel>> searchGames(GameSearchParams params) async {
    final body = await _api.get(
      ApiEndpoints.searchGames,
      queryParams: params.toQueryParams(),
    );
    // Backend returns { success, games, pagination }, not data.games
    final list = (body['games'] as List<dynamic>?) ?? [];
    return list
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Get single game ───────────────────────────────────────
  Future<GameModel> getGame(String id) async {
    final body = await _api.get(ApiEndpoints.game(id));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── My games ──────────────────────────────────────────────
  Future<List<GameModel>> getMyGames() async {
    final body = await _api.get(ApiEndpoints.myGames);
    final data = body['data'] as Map<String, dynamic>;
    final list = data['games'] as List<dynamic>;
    return list
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Calendar (upcoming joined games) ─────────────────────
  Future<List<GameModel>> getCalendar() async {
    final body = await _api.get(ApiEndpoints.calendar);
    final data = body['data'] as Map<String, dynamic>;
    final list = data['games'] as List<dynamic>;
    return list
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Create ────────────────────────────────────────────────
  Future<GameModel> createGame(Map<String, dynamic> payload) async {
    final body = await _api.post(ApiEndpoints.games, data: payload);
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Update ────────────────────────────────────────────────
  Future<GameModel> updateGame(
      String id, Map<String, dynamic> updates) async {
    final body = await _api.patch(ApiEndpoints.game(id), data: updates);
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Cancel ────────────────────────────────────────────────
  Future<void> cancelGame(String id) =>
      _api.post(ApiEndpoints.cancelGame(id));

  // ── Join ──────────────────────────────────────────────────
  Future<GameModel> joinGame(String id) async {
    final body = await _api.post(ApiEndpoints.joinGame(id));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Leave ─────────────────────────────────────────────────
  Future<GameModel> leaveGame(String id) async {
    final body = await _api.post(ApiEndpoints.leaveGame(id));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Approve player ────────────────────────────────────────
  Future<GameModel> approvePlayer(String gameId, String userId) async {
    final body = await _api.post(
      ApiEndpoints.approvePlayer(gameId),
      data: {'userId': userId},
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Kick player ───────────────────────────────────────────
  Future<GameModel> kickPlayer(String gameId, String userId) async {
    final body = await _api.post(
      ApiEndpoints.kickPlayer(gameId),
      data: {'userId': userId},
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Complete ──────────────────────────────────────────────
  Future<GameModel> completeGame(
      String id, Map<String, dynamic> result) async {
    final body = await _api.post(
      ApiEndpoints.completeGame(id),
      data: result,
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Pending requests ──────────────────────────────────────
  Future<List<GamePlayer>> getPendingRequests(String gameId) async {
    final body =
        await _api.get(ApiEndpoints.gamePendingRequests(gameId));
    final data = body['data'] as Map<String, dynamic>;
    final list = data['players'] as List<dynamic>;
    return list
        .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
