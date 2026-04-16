# ─── Stage 1: Build ───────────────────────────────────────────────────────────
# Uses the official Flutter Docker image
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app

# Copy dependency manifest and resolve packages
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source
COPY . .

# Build a release APK (Android)
# To build iOS: remove this and run on a macOS runner / Xcode Cloud
RUN flutter build apk --release \
      --dart-define=API_BASE_URL=${API_BASE_URL:-https://api.buddbull.app/api/v1}

# ─── Stage 2: Artifact export ─────────────────────────────────────────────────
FROM alpine:3.20 AS artifact
WORKDIR /artifacts

COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk ./buddbull-release.apk

# The APK is available at /artifacts/buddbull-release.apk
# Use `docker cp` or a volume mount to extract it.
CMD ["sh", "-c", "echo 'APK available at /artifacts/buddbull-release.apk'; ls -lh /artifacts"]
