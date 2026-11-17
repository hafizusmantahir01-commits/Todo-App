# Todo App v2 – Flutter (Android)

Offline to-do app jo din ko **namaz ke waqt** ke hisaab se plan karti hai, aur **Roman Urdu + English** dono samajhti hai.
Koi login nahi, koi internet nahi, sara data sirf phone mein.

## v1 se v2 par update kaise karein (zaroori)

Purani `lib` aur `test` folder **pehle delete** karni hain, warna purani files ki wajah se errors aayenge.
PowerShell, `E:\Projects\Todo-App` ke andar:

```powershell
Remove-Item -Recurse -Force lib, test
Expand-Archive "$env:USERPROFILE\Downloads\todo-app-v2.zip" -DestinationPath "$env:TEMP\todov2" -Force
Copy-Item "$env:TEMP\todov2\todo_app\*" -Destination "." -Recurse -Force

# App ka naam capital T ke saath ("Todo App")
(Get-Content android\app\src\main\AndroidManifest.xml) -replace 'android:label="[^"]*"', 'android:label="Todo App"' | Set-Content android\app\src\main\AndroidManifest.xml

flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter test
flutter analyze
flutter build apk --release
```

APK: `build\app\outputs\flutter-apk\app-release.apk`

Note: Phone par purani app pehle se install ho to data (tasks) wahi rahega aur onboarding dobara nahi aayegi.
Naya onboarding dekhna ho to phone Settings > Apps > Todo App > Storage > Clear data.

## Screens

| Tab / Screen | Kya hai |
|---|---|
| Onboarding (3) | Live typing demo, namaz ke saath planning, setup (naam, lists, shehar, Light/Dark) |
| Today | Day arc (sooraj + Fajr se Isha), "Top 3", kaam namaz ke waqt ke groups mein, overdue, purane kaam ki safai |
| Quick add (+) | Smart typing jo samjhe gaye lafz rang deti hai, Today/Tomorrow/Weekend, "After Maghrib" jaise buttons, priority, list, repeat, steps, templates |
| Task detail | Steps, waqt, kitna time lagega, priority, list, repeat, effort, Top 3, tags, notes, Focus |
| Planner | Hafte ki strip (har din kitna busy), din ke time blocks, namaz ki lines, khali waqt par tap karke task |
| Habits | Roz ki aadatein (check ya count, jaise 8 glass paani), streak, 7 din ka record |
| Focus | Timer: 1 se 180 minute tak koi bhi length, + / − buttons, 15/25/45/60/90 shortcuts, breaks bhi set ho sakte hain |
| Review | Din ka khulasa, bache kaam kal par, mood, ek line ki diary, hafte ki insights |
| Profile & settings | Naam, Light/Dark/Auto, prayer times on/off, shehar, Asr (Hanafi/Shafi), lists, export, delete all, privacy, contact |

## Back button rules

| Kahan | Back | Natija |
|---|---|---|
| Planner / Habits / Review tab | Back | Today tab |
| Today tab | Back | App close |
| Koi bhi andar ki screen | Back | Pichli screen |
| Focus timer chal raha ho | Back | "Stop this session?" |
| Brain dump review | Back | Edit par wapas |
| Onboarding page 2/3 | Back | Pichla page |

## Design

- Font: Plus Jakarta Sans (app ke andar bundled, `assets/fonts`, OFL license)
- Light: skin/cream background, white cards, orange buttons, black accents
- Dark: black background, orange buttons
- Saare rang `lib/theme/app_colors.dart` mein ek jagah hain

## Signed APK / AAB (Play Store ke liye)

`android_setup/` folder dekho: `key.properties.example` aur `signing_snippet.gradle.kts`.

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
flutter build appbundle --release
```

`.jks` aur `android/key.properties` kabhi GitHub par push mat karna (`.gitignore` mein pehle se hain).

## Play Store assets

| Asset | File |
|---|---|
| App icon 512×512 | `store_assets/app_icon_512.png` |
| Feature graphic 1024×500 | `store_assets/feature_graphic_1024x500.png` |
| Phone screenshots 9:16 | emulator/phone se lo (1080×1920) |
| Privacy policy | `docs/privacy-policy.html` → GitHub Pages par host karo |

## Project structure

```
lib/
  main.dart
  theme/            app_colors.dart (rang), app_theme.dart (font, theme)
  data/store.dart   saara data aur settings (phone mein save)
  models/           task.dart, habit.dart
  utils/            smart_parser.dart, prayer_times.dart, dates.dart
  widgets/          common.dart, task_tile.dart, day_arc.dart, smart_text_controller.dart
  screens/          har screen ki file
assets/fonts/       Plus Jakarta Sans
test/               smart typing + prayer times tests
```
