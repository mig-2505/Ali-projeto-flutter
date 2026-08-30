# ali

Flutter app. Single-screen mobile UI for a local-producer marketplace.

## Project Structure

- `lib/main.dart` - Entire app: theme, mock data (categories/producers/products), and all screens (home feed, cart, order success, explore/profile placeholders). Entry point is `main()`.
- `pubspec.yaml` - Dependencies and app metadata.
- `analysis_options.yaml` - Lint rules (`flutter_lints`).

Platform folders (`android/`, `ios/`, `web/`, etc.) aren't checked in yet — run `flutter create .` in the project root once to generate them for the platforms you target.

## Dependencies

- `google_fonts` - Loads the Fraunces (headings) / Outfit (body) typefaces used by the original design, fetched from Google Fonts at runtime and cached on-device.
- `flutter_lints` (dev) - Standard lint set.

## Running

```
flutter pub get
flutter run
```

## Code quality

- Keep state in `_AliHomePageState`; screens are stateless widgets that receive data and callbacks as constructor params.
- Reuse the `_iconBox` helper in `lib/main.dart` for small square/circular icon buttons instead of duplicating `Container` + `Icon` boilerplate.
