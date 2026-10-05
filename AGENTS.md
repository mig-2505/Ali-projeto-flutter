# ali

Flutter app. Single-screen mobile UI for a local-producer marketplace.

## Project Structure

- `lib/main.dart` - Entire app: theme, models, API client (`apiUrl`, `apiGet`), and all screens (home feed, cart, order success, explore/profile placeholders). Entry point is `main()`.
- `pubspec.yaml` - Dependencies and app metadata.
- `analysis_options.yaml` - Lint rules (`flutter_lints`).
- `backend/` - Python + Flask API over SQLite. `schema.sql` holds tables + seed data (applied when the DB file doesn't exist); `app.py` holds all routes; `test_app.py` is a plain-assert check (`python test_app.py`).
- `docker-compose.yml` - Runs `web` (Flutter build on :8090) and `api` (:5000, DB in the `ali-data` volume).

Platform folders (`android/`, `ios/`, `web/`, etc.) aren't checked in yet — run `flutter create .` in the project root once to generate them for the platforms you target.

## Dependencies

- `google_fonts` - Loads the Fraunces (headings) / Outfit (body) typefaces used by the original design, fetched from Google Fonts at runtime and cached on-device.
- `http` - Calls the backend API.
- `flutter_lints` (dev) - Standard lint set.

## Running

```
docker compose up -d --build     # app :8090 + API :5000
```

Or without Docker: `cd backend && pip install -r requirements.txt && python app.py`, then `flutter pub get && flutter run`. The API URL defaults to `http://localhost:5000`; override with `--dart-define=API_URL=...`.

## Code quality

- Keep state in `_AliHomePageState`; screens are stateless widgets that receive data and callbacks as constructor params.
- Reuse the `_iconBox` helper in `lib/main.dart` for small square/circular icon buttons instead of duplicating `Container` + `Icon` boilerplate.
