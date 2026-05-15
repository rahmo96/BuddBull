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

    // TEMP DEBUG (remove later)
    // ignore: avoid_print
    print('[BB][searchGames] raw list=$list');

    final games = <GameModel>[];
    for (var i = 0; i < list.length; i++) {
      final raw = list[i];
      // ignore: avoid_print
      print(
          '[BB][searchGames] index=$i raw.runtimeType=${raw.runtimeType} raw=$raw');

      if (raw is Map<String, dynamic>) {
        final id = raw['_id'] ?? raw['id'];
        final organizer = raw['organizer'];
        final location = raw['location'];
        final groupChat = raw['groupChat'];
        final sport = raw['sport'];

        // ignore: avoid_print
        print('[BB][searchGames] game[$i] id=$id');
        // ignore: avoid_print
        print(
            '[BB][searchGames] game[$i] organizer.runtimeType=${organizer.runtimeType} value=$organizer');
        // ignore: avoid_print
        print(
            '[BB][searchGames] game[$i] location.runtimeType=${location.runtimeType} value=$location');
        // ignore: avoid_print
        print(
            '[BB][searchGames] game[$i] groupChat.runtimeType=${groupChat.runtimeType} value=$groupChat');
        // ignore: avoid_print
        print(
            '[BB][searchGames] game[$i] sport.runtimeType=${sport.runtimeType} value=$sport');
      } else {
        // ignore: avoid_print
        print(
            '[BB][searchGames] game[$i] is not a Map, skipping field-level debug');
      }

      try {
        games.add(GameModel.fromJson(raw as Map<String, dynamic>));
      } catch (e, st) {
        // ignore: avoid_print
        print('[BB][searchGames] ERROR parsing game[$i]: $e\n$st');
        rethrow;
      }
    }

    return games;
  }

  // ── Get single game ───────────────────────────────────────
  Future<GameModel> getGame(String id) async {
    final body = await _api.get(ApiEndpoints.game(id));
    final data = body['data'] as Map<String, dynamic>;

    // TEMP DEBUG (remove later)
    final rawGame = data['game'];

    // runtimeType of raw response + raw response data
    // ignore: avoid_print
    print('[BB][getGame] rawGame.runtimeType=${rawGame.runtimeType}');
    // ignore: avoid_print
    print('[BB][getGame] rawGame=$rawGame');

    // runtimeType and value of sport, groupChat, organizer, location, result
    final sport = (rawGame is Map) ? rawGame['sport'] : null;
    final groupChat = (rawGame is Map) ? rawGame['groupChat'] : null;
    final organizer = (rawGame is Map) ? rawGame['organizer'] : null;
    final location = (rawGame is Map) ? rawGame['location'] : null;
    final result = (rawGame is Map) ? rawGame['result'] : null;

    // ignore: avoid_print
    print('[BB][getGame] sport.runtimeType=${sport.runtimeType} value=$sport');
    // ignore: avoid_print
    print(
        '[BB][getGame] groupChat.runtimeType=${groupChat.runtimeType} value=$groupChat');
    // ignore: avoid_print
    print(
        '[BB][getGame] organizer.runtimeType=${organizer.runtimeType} value=$organizer');
    // ignore: avoid_print
    print(
        '[BB][getGame] location.runtimeType=${location.runtimeType} value=$location');
    // ignore: avoid_print
    print(
        '[BB][getGame] result.runtimeType=${result.runtimeType} value=$result');

    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── My games ──────────────────────────────────────────────
  Future<List<GameModel>> getMyGames() async {
    final body = await _api.get(ApiEndpoints.myGames);
    // Backend returns { success, games, pagination }, not data.games
    final list = (body['games'] as List<dynamic>?) ?? [];
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
  Future<GameModel> updateGame(String id, Map<String, dynamic> updates) async {
    final body = await _api.patch(ApiEndpoints.game(id), data: updates);
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Cancel ────────────────────────────────────────────────
  Future<void> cancelGame(String id, {required String reason}) {
    return _api.delete(
      ApiEndpoints.game(id),
      data: {'reason': reason},
    );
  }

  // ── Join ──────────────────────────────────────────────────
  Future<GameModel> joinGame(String id, {bool acceptInvite = false}) async {
    final body = await _api.post(ApiEndpoints.joinGame(id, acceptInvite: acceptInvite));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Leave ─────────────────────────────────────────────────
  Future<void> leaveGame(String id) async {
    await _api.delete(ApiEndpoints.leaveGame(id));
  }

  // ── Approve player ────────────────────────────────────────
  // Real backend route: `PATCH /games/:id/players/:userId/approve`
  // (no body — both ids are in the URL).
  Future<GameModel> approvePlayer(String gameId, String userId) async {
    final body = await _api.patch(ApiEndpoints.approvePlayer(gameId, userId));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Kick player ───────────────────────────────────────────
  // Real backend route: `DELETE /games/:id/players/:userId`.
  Future<GameModel> inviteFriend(String gameId, String friendId) async {
    final body = await _api.post(ApiEndpoints.inviteFriendToGame(gameId, friendId));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  Future<GameModel> cancelInvite(String gameId, String userId) async {
    final body = await _api.delete(ApiEndpoints.cancelGameInvite(gameId, userId));
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  Future<GameModel> kickPlayer(String gameId, String userId,
      {String? reason}) async {
    final body = await _api.delete(
      ApiEndpoints.kickPlayer(gameId, userId),
      data: reason == null ? null : <String, dynamic>{'reason': reason},
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  /// Approve / reject a pending join request in a single call.
  ///
  /// Powers the bell-inbox "Approve" / "Reject" quick actions. Mapped
  /// to the backend's `PATCH /games/:id/join-request/:userId` endpoint
  /// which internally routes to the same approve/kick code paths and
  /// fires the matching downstream notification (`gameApproved` /
  /// `gameKicked`).
  Future<GameModel> handleJoinRequest({
    required String gameId,
    required String userId,
    required String decision,
    String? reason,
  }) async {
    assert(decision == 'approve' || decision == 'reject',
        "decision must be 'approve' or 'reject'");
    final body = await _api.patch(
      ApiEndpoints.gameJoinRequest(gameId, userId),
      data: <String, dynamic>{
        'decision': decision,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Complete ──────────────────────────────────────────────
  // Backend route is PATCH /games/:id/complete. Payload fields are all optional
  // (winnerDescription, score, mvpUserId, notes). Pass an empty map to mark
  // the game completed without recording a result.
  Future<GameModel> completeGame(String id, [Map<String, dynamic>? result]) async {
    final body = await _api.patch(
      ApiEndpoints.completeGame(id),
      data: result ?? const <String, dynamic>{},
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameModel.fromJson(data['game'] as Map<String, dynamic>);
  }

  // ── Pending requests ──────────────────────────────────────
  Future<List<GamePlayer>> getPendingRequests(String gameId) async {
    final body = await _api.get(ApiEndpoints.gamePendingRequests(gameId));
    final data = body['data'] as Map<String, dynamic>;
    final list = data['players'] as List<dynamic>;
    return list
        .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AddressSuggestion>> autocompleteAddress(String input) async {
    final body = await _api.get(
      ApiEndpoints.mapsAutocomplete,
      queryParams: {'input': input},
    );
    final data = body['data'] as Map<String, dynamic>;
    final list = data['suggestions'] as List<dynamic>? ?? [];
    return list
        .map((e) => AddressSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GameLocation> getPlaceDetails(String placeId) async {
    final body = await _api.get(
      ApiEndpoints.mapsPlaceDetails,
      queryParams: {'placeId': placeId},
    );
    final data = body['data'] as Map<String, dynamic>;
    return GameLocation.fromJson(data['location'] as Map<String, dynamic>);
  }
}

class AddressSuggestion {
  const AddressSuggestion({
    required this.placeId,
    required this.description,
    this.primaryText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? primaryText;
  final String? secondaryText;

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) =>
      AddressSuggestion(
        placeId: json['placeId'] as String,
        description: json['description'] as String,
        primaryText: json['primaryText'] as String?,
        secondaryText: json['secondaryText'] as String?,
      );
}
