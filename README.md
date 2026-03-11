# sporsal

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Mapbox City Night Gold

This project supports a Mapbox-based map style named `City Night Gold`.

### Runtime defines

- `MAPBOX_ACCESS_TOKEN`: Mapbox public access token
- `MAPBOX_STYLE_ID`: Optional style ID (default: `navigation-night-v1`)

If `MAPBOX_ACCESS_TOKEN` is not provided, the app automatically falls back to CARTO dark tiles.

### Build examples

```powershell
flutter build web --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_TOKEN --dart-define=MAPBOX_STYLE_ID=navigation-night-v1
```

```powershell
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_TOKEN --dart-define=MAPBOX_STYLE_ID=navigation-night-v1
```

### Deploy example

```powershell
flutter build web --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_TOKEN --dart-define=MAPBOX_STYLE_ID=navigation-night-v1
firebase deploy
```
