# Todo App v2 – Testing Report

| Field | Value |
|---|---|
| App version | 2.0.0 (2) |
| Device(s) | |
| Tester | |
| Date | |

Har test ke aage Pass / Fail likho. Fail ho to Notes mein steps likho.

## 1. Look & text

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| L1 | Home screen par app ka naam | "Todo App" (capital T) | | |
| L2 | Har screen ka font | Ek jaisa (Plus Jakarta Sans) | | |
| L3 | Icon + text wali lines (task meta, settings rows) | Icon aur text ek seedh mein, upar neeche nahi | | |
| L4 | Light theme | Skin/cream + white + orange + black | | |
| L5 | Dark theme (Profile > Look > Dark) | Black + orange, sab text parhne layak | | |
| L6 | Bara font (phone Settings > Font size max) | Text kat'ta nahi, layout nahi tootta | | |

## 2. Navigation

| # | Steps | Expected | Result | Notes |
|---|---|---|---|---|
| N1 | Fresh install | Onboarding page 1, typing animation chalti hai | | |
| N2 | Page 3 par Back | Page 2 | | |
| N3 | Start my day → Back | App close | | |
| N4 | Planner / Habits / Review → Back | Today tab | | |
| N5 | Today → Back | App close | | |
| N6 | Today → Profile → Lists → list → task → Back ×4 | Ulti tarteeb mein wapas Today | | |
| N7 | + sheet khula → Back | Sheet band, kuch save nahi | | |
| N8 | Focus chal raha → Back | "Stop this session?" | | |
| N9 | Brain dump review → Back | Edit step | | |

## 3. Tasks & smart typing

| # | Type / Action | Expected | Result | Notes |
|---|---|---|---|---|
| T1 | `kal shaam 6 baje gym #Health !high` | Gym, kal 6 PM, Health, High; lafz rang mein | | |
| T2 | `ammi ko call kal Maghrib ke baad` | Kal, Maghrib + 15 min | | |
| T3 | `assignment zuhr se pehle` | Aaj, Zuhr − 30 min | | |
| T4 | "After Asr" button | Time Asr + 15 min | | |
| T5 | Steps button → 3 lines | 3 steps ban jayein | | |
| T6 | Template "Exam prep" | 5 tasks, Study list | | |
| T7 | Swipe right / left + Undo | Done / Delete wapas | | |
| T8 | Task detail → Top 3 on | Today ke black card mein | | |
| T9 | 4th task Top 3 karo | "You already have 3" message | | |
| T10 | Repeat task complete | Agla task agli date par | | |

## 4. Planner, Habits, Focus, Review

| # | Steps | Expected | Result | Notes |
|---|---|---|---|---|
| P1 | Planner mein kal ka din | Us din ke blocks + namaz lines | | |
| P2 | "Free 1h" par tap | Usi waqt ke saath add sheet | | |
| H1 | Habit idea "Drink water" | Count habit, +1 se 8 tak | | |
| H2 | Habit tap → edit / delete | Kaam kare | | |
| F1 | Focus: + / − buttons | 5 min kam/zyada, 1 se 180 ke beech | | |
| F2 | Tune icon → sliders | Focus/break length save ho | | |
| F3 | 1 min ka timer complete | Vibration + break mode | | |
| R1 | Review → Move all | Bache kaam kal par | | |
| R2 | Mood + note, app band kar ke kholo | Save rahe | | |

## 5. Settings & release

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| S1 | Prayer times off | Arc 6 AM–10 PM, groups Morning/Afternoon/Evening | | |
| S2 | City Karachi | Times badal jayein | | |
| S3 | Export data | Clipboard mein JSON | | |
| S4 | Delete all data | Sab saaf, crash nahi | | |
| S5 | Airplane mode | Sab kaam kare | | |
| S6 | App permissions | Koi permission nahi | | |
| S7 | `flutter test` / `flutter analyze` | Pass / No issues | | |

## Summary

| Total | Passed | Failed |
|---|---|---|
| | | |
