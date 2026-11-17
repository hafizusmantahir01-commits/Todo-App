# Todo App v3 – Flutter (Android)

Din ko **namaz ke waqt** ke hisaab se plan karne wali to-do app. **English / اردو / Roman Urdu**, light aur dark theme.
Koi login nahi; data sirf phone mein.

## Install / update (PowerShell, `E:\Projects\Todo-App` ke andar)

Har block alag chalao.

**1. Zip dhoondo**
```powershell
$zip = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-ChildItem "$($_.Root)" -Filter "todo-app-v3*.zip" -Recurse -ErrorAction SilentlyContinue } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($zip) { "MIL GAYA: " + $zip.FullName } else { "ZIP NAHI MILA" }
```

**2. Sirf jab "MIL GAYA" aaye**
```powershell
Expand-Archive $zip.FullName -DestinationPath "$env:TEMP\todo3" -Force
Remove-Item -Recurse -Force lib, test -ErrorAction SilentlyContinue
Copy-Item "$env:TEMP\todo3\todo_app\*" -Destination "E:\Projects\Todo-App" -Recurse -Force
Select-String -Path pubspec.yaml -Pattern "version:"
```
`version: 3.3.2+15` aana chahiye. Is copy se `android` folder ki kuch files bhi badlti hain (AndroidManifest, build.gradle.kts, MainActivity.kt, widget) — yeh zaroori hai.

**3. Build**
```powershell
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter build apk --release
```
APK: `build\app\outputs\flutter-apk\app-release.apk`. Phone se purani app uninstall karke nayi install karo.

## Features

| Feature | Kahan |
|---|---|
| Language: English / اردو / Roman Urdu (Urdu right-to-left) | Onboarding upar "Language", ya Profile > Language |
| Onboarding (3 screens) + Profile (naam, photo / avatar / harf) + setup | Pehli dafa |
| Day arc: sooraj, Fajr se Isha, Hijri date | Today |
| Ramzan mode: Sehri / Iftar arc par + reminders (Auto / On / Off) | Profile > Prayer times |
| Smart typing: English, Roman Urdu, Urdu script ("کل شام ۶ بجے جم") | + button |
| Bol kar task (mic) | + sheet ka mic button |
| Task reminders (5, 10, 15, 30, 60 min pehle) | + sheet ya Task detail |
| Namaz alerts, subah ka khulasa, Sunday weekly reminder | Profile > Reminders |
| Weekly planning: 3 goals + undated tasks ko din | Today card (Sat/Sun/Mon), Review, Profile |
| Planner: time blocks, namaz lines, khali waqt, phone calendar | Planner tab |
| Habits + streaks | Habits tab |
| Focus timer: 1–180 min, +/−, sounds (Rain, White, Deep) | Task > Focus |
| Day review: mood, note, bache kaam kal par, hafte ki insights | Review tab |
| Backup file save / restore | Profile > Your data |
| Home-screen widget: aaj ke top 3 | Home screen par long-press > Widgets > Todo App |

## Permissions (sirf feature use karne par maangi jati hain)

| Permission | Kis liye |
|---|---|
| Notifications | Reminders |
| Microphone | Bol kar task |
| Calendar (read only) | Planner mein phone calendar |
| Photos / camera | Profile photo (Android photo picker; alag permission nahi) |

Play Console ke **Data safety** form ke liye: app khud koi data server par nahi bhejti, account nahi, ads/analytics nahi. Mic wala text phone ki speech service banati hai (privacy policy mein likha hai).

## Translations

Saare texts `lib/l10n/translations.dart` mein hain (left: English, right: Urdu / Roman Urdu).
Koi lafz badalna ho to sirf right side badlo.

## Back button

| Kahan | Back |
|---|---|
| Planner / Habits / Review | Today tab |
| Today | App band |
| Andar ki screens | Pichli screen |
| Focus chal raha ho | "Stop this session?" |

## Signed APK / AAB (Play Store)

`android/key.properties` bana do (`android_setup/key.properties.example` dekho) aur keystore `android/app/upload-keystore.jks` mein rakho.
`build.gradle.kts` khud dekh leta hai: key.properties ho to release signing, warna debug signing.
```powershell
flutter build appbundle --release
```

## Structure

```
lib/
  l10n/          strings.dart (tr), translations.dart (Urdu, Roman)
  services/      notifications, native (calendar, widget), widget_sync, sound, backup
  data/store.dart
  models/        task, habit
  utils/         smart_parser, prayer_times, hijri, dates
  widgets/       common, task_tile, day_arc, user_avatar, smart_text_controller
  screens/       har screen
android/app/src/main/   AndroidManifest.xml, MainActivity.kt, TodoWidgetProvider.kt, widget layout
assets/          fonts (Plus Jakarta Sans, Noto Naskh Arabic), sounds, icon
```
