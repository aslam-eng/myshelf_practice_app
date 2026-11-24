# My Product Shelf

A small Flutter Android app to browse products, save favourites, edit a profile
and send a demo product request. Built for the Flutter intern two-day assignment.

## Setup

1. Install Flutter (stable channel, Dart SDK 3.13 or newer) and an Android emulator or phone.
2. Clone the repository and fetch packages:
   ```
   git clone https://github.com/aslam-eng/myshelf_practice_app.git
   cd myshelf_practice_app
   flutter pub get
   ```
3. Run the app: `flutter run`
4. Run the tests: `flutter test`
5. Build the debug APK: `flutter build apk --debug`
   (output: `build/app/outputs/flutter-apk/app-debug.apk`)

Packages: `provider`, `http`, `image_picker`, `shared_preferences`.

## Completed features

- **Home:** loads 12 products from DummyJSON (image, title, category, price, save button),
  local title search with a no-results state, pull-to-refresh without duplicates,
  loading / error-with-Retry / empty states, and a broken-image fallback.
- **Saved:** the same Provider data as Home, with a remove action, an instant saved count,
  and a "No saved products yet" state with a Browse products button.
- **Profile:** edit and save the display name; pick a photo from the gallery
  (cancelling keeps the current photo); initials avatar placeholder; camera button using Stack + Positioned.
- **Add product:** title (≥ 3 characters) and price (> 0) validation with errors under the fields,
  POST to DummyJSON, "Sending..." with the button disabled, the returned product id on success,
  and a retryable error that keeps the input.
- **Storage:** display name and saved products (id, title, category, price, thumbnail) are kept
  in `shared_preferences` as JSON and survive a full restart; saved titles and prices work offline.
- **Errors:** timeouts (10 s), no internet, non-2xx status codes and invalid JSON all show a clear message.
- **Tests:** model / JSON tests, a service test, and a widget test for the Save button.

## Project structure

```
lib/
  main.dart                     loads saved data, sets up providers and theme
  models/product.dart           Product model with fromJson / toJson
  services/product_service.dart GET products + POST add product (timeout, errors)
  services/storage_service.dart shared_preferences helpers (name, saved products)
  services/api_exception.dart   clean error messages for the UI
  providers/favourites_provider.dart  shared favourites (ChangeNotifier)
  providers/profile_provider.dart     shared display name (ChangeNotifier)
  screens/main_shell.dart       bottom navigation (IndexedStack)
  screens/home_screen.dart
  screens/saved_screen.dart
  screens/profile_screen.dart
  screens/add_product_screen.dart
  widgets/product_card.dart     product card used by Home and Saved
```

## Where the main concepts are used

**Provider (ChangeNotifier)**
- `FavouritesProvider`: one shared favourites list for Home and Saved. `toggle()` calls
  `notifyListeners()` so both tabs update instantly, then saves to storage.
- `ProfileProvider`: the saved display name, shown on Home ("Hello, …") and edited on Profile.
- `context.watch` in `build` for listening UI (`ProductCard`, `SavedScreen`, Home greeting);
  `context.read` in callbacks (Save button, Save profile, initial name in `initState`).
- Providers are created in `main()` above `MaterialApp`, so every screen,
  including pushed routes, can find them.
  - `ProductsProvider`: the search text; Home's count and list rebuild through `Consumer` while typing.

**setState (local UI state only)**
- `HomeScreen`: product list, loading / error state.
- `ProfileScreen`: selected photo preview, saving state, "Profile saved" message.
- `AddProductScreen`: sending state, returned id, error message.
- `MainShell`: selected tab index.
- Favourites are never copied into `setState`; they always come from the provider.

**initState**
- `HomeScreen`: starts loading products once (never in `build`).
- `ProfileScreen`: fills the name field from the provider with `context.read`.

**dispose**
- Every screen disposes the `TextEditingController`s it creates
  (Home search, Profile name, Add product title and price).

**mounted**
- Checked before every `setState` after an `await` (Home loading, photo picking,
  saving the name, the POST request), so leaving a screen mid-request causes no error.

## Lifecycle order (logged in `AddProductScreen` and `HomeScreen`)

Opening the Add product bottom sheet, typing, then closing it prints:

```
AddProductScreen: initState   created once: one-time setup
AddProductScreen: build       first draw
AddProductScreen: build       redrawn after each setState
AddProductScreen: dispose     removed once: controllers cleaned up
```

`initState` runs once when the widget is created, `build` runs every time the UI must be
redrawn, and `dispose` runs once when the widget is removed. Home lives inside an
`IndexedStack`, so switching tabs only hides it; its `initState` does not run again and
products are not reloaded.

## Known issues / limitations

- The profile photo is not stored: it resets after an app restart
  (persistence is optional for this assignment).
- DummyJSON only simulates POST: the new product is not saved and does not appear on Home.
- Product images need internet; offline, Saved shows placeholders (titles and prices still show).
- `test/product_service_test.dart` calls the real API, so it fails without internet.
- The error handling in `ProductService` is repeated in both methods; it could be moved into a shared helper.

## Outside help

- **Claude (Anthropic), used as a mentor in the editor.** It explained each concept and
  proposed code step by step; I answered check questions before each part was written,
  ran and tested the app on a device, and can explain or modify any part of it.
  The model, the first GET service and the model / JSON / service tests were started by me;
  the remaining screens, providers, services and the widget test were written with Claude's guidance.
- Official docs: dummyjson.com/docs/products and the pub.dev pages for provider, http,
  image_picker and shared_preferences.
