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

Packages: `provider`, `http`, `image_picker`, `shared_preferences`, `path_provider`.

## Completed features

- **Home:** loads products from DummyJSON 12 at a time (image, title, category, price, save button),
  server search over all products (`/products/search`) with a no-results state, pull-to-refresh without duplicates,
  loading / error-with-Retry / empty states, and a broken-image fallback.
- **Pagination:** a `ScrollController` loads the next page (`limit=12&skip=<loaded>`) when the
  user is 200 px from the bottom, with a small spinner at the end of the list. `loadMore()` has a
  guard (one request at a time, stop at `total`), and a failed page shows Retry instead of
  firing again on every scroll. Search results are paginated the same way.
- **Search:** typing is debounced (one request after a 400 ms pause, not one per letter), the URL
  is built with `Uri.https` so user input is encoded, and each list load takes a "ticket" number
  so a slow, outdated response can never overwrite newer results.
- **Saved:** the same Provider data as Home, with a remove action, an instant saved count,
  and a "No saved products yet" state with a Browse products button.
- **Profile:** edit and save the display name; pick a photo from the gallery
  (cancelling keeps the current photo); initials avatar placeholder; camera button using Stack + Positioned.
- **Add product:** title (≥ 3 characters) and price (> 0) validation with errors under the fields,
  POST to DummyJSON, "Sending..." with the button disabled, the returned product id on success,
  and a retryable error that keeps the input.
- **Storage:** display name and saved products (id, title, category, price, thumbnail) are kept
  in `shared_preferences` as JSON and survive a full restart; saved titles and prices work offline.
  The profile photo is copied into the app's documents folder (`path_provider`) and only its
  path is stored in `shared_preferences`, so it also survives a restart.
- **Errors:** timeouts (10 s), no internet, dropped connections, non-2xx status codes and invalid JSON
  all show a clear message (one place: `ApiException.from`).
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
  providers/products_provider.dart    Home's products, loading / error, search (ChangeNotifier)
  screens/main_shell.dart       bottom navigation (IndexedStack)
  screens/home_screen.dart
  screens/saved_screen.dart
  screens/profile_screen.dart
  screens/add_product_screen.dart
  widgets/product_card.dart     product card used by Home and Saved
```

## Where the main concepts are used

**Provider (ChangeNotifier)**
- `FavouritesProvider`: one shared favourites list for Home and Saved. `toggle()` saves to
  storage first, then calls `notifyListeners()` so both tabs update; if saving fails, nothing
  changes and the card shows an error SnackBar.
- `ProfileProvider`: the saved display name, shown on Home ("Hello, …") and edited on Profile,
  and the saved photo path. Both write to disk first, then update the screen.
- `ProductsProvider`: Home's products, loading / error state and search text. `loadProducts()`
  replaces the list (never duplicates); a failed refresh keeps the old products and rethrows,
  so Home shows a SnackBar. The first load starts in `main()` when the provider is created.
  It owns the debounce `Timer` and cancels it in `dispose()`.
  Home's count and list rebuild through `Consumer`.
- `context.watch` in `build` for listening UI (`ProductCard`, `SavedScreen`, Home greeting);
  `context.read` in callbacks (Save button, Save profile, initial name in `initState`).
- Providers are created in `main()` above `MaterialApp`, so every screen,
  including pushed routes, can find them.

**setState (local UI state only)**
- `ProfileScreen`: saving state, "Profile saved" message, name error.
- `AddProductScreen`: sending state, returned id, error message.
- `MainShell`: selected tab index.
- Favourites are never copied into `setState`; they always come from the provider.

**initState**
- `HomeScreen`: only logs; loading starts in the provider's `create`, because calling
  `notifyListeners()` while Flutter is building a screen throws an error.
- `ProfileScreen`: fills the name field from the provider with `context.read`.

**dispose**
- Every screen disposes the controllers it creates
  (Home search + `ScrollController`, Profile name, Add product title and price).

**mounted**
- Checked before every `setState` after an `await` (photo picking, saving the name,
  the POST request), so leaving a screen mid-request causes no error.
- Where a widget has no `mounted` (or may be removed), `ScaffoldMessenger` and providers
  are grabbed BEFORE the `await` instead (Home refresh, Save button).

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

- The photo's full path is stored. That is stable on Android (this app's target); on iOS the
  app folder can change after an update, so storing only the file name would be safer there.
- DummyJSON only simulates POST: the new product is not saved and does not appear on Home.
- Product images need internet; offline, Saved shows placeholders (titles and prices still show).
- `test/product_service_test.dart` calls the real API, so it fails without internet.

## Outside help

- **Claude (Anthropic), used as a mentor in the editor.** It explained each concept and
  proposed code step by step; I answered check questions before each part was written,
  ran and tested the app on a device, and can explain or modify any part of it.
  The model, the first GET service and the model / JSON / service tests were started by me;
  the remaining screens, providers, services and the widget test were written with Claude's guidance.
- Official docs: dummyjson.com/docs/products and the pub.dev pages for provider, http,
  image_picker and shared_preferences.
