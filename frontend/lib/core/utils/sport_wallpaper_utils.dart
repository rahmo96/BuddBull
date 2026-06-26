/// Maps game sport names to bundled wallpaper assets under [assets/wallpapers/].
abstract class SportWallpaperUtils {
  static String? assetPathForSport(String sport) {
    return switch (sport.toLowerCase()) {
      'football' || 'soccer' => 'assets/wallpapers/football_game.jpg',
      'basketball' => 'assets/wallpapers/basketball_game.jpg',
      'tennis' => 'assets/wallpapers/tennis_game.jpg',
      'running' => 'assets/wallpapers/running_game.jpg',
      'swimming' => 'assets/wallpapers/swimming_game.jpg',
      'cycling' => 'assets/wallpapers/cycling_game.jpg',
      'volleyball' => 'assets/wallpapers/volleyball_game.jpg',
      'cricket' => 'assets/wallpapers/creicket_game.png',
      _ => null,
    };
  }

  SportWallpaperUtils._();
}
