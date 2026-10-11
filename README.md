# YGO Shuffle 🃏🎰

**A customizable rule generator that makes every Yu-Gi-Oh! duel unpredictable.**

YGO Shuffle is an iOS app built with **SwiftUI**. It adds a random twist to duels by generating an extra effect at the start of each player's Standby Phase. Whether you're playing competitively or casually, the generator can change the game in an instant.

## Features

- 🎰 **Slot-machine-style rule generator** with animated spins.
- 🃏 **Built-in rule list** with draw effects, Life Point changes, summoning restrictions, field wipes, and more.
- 📝 **Custom rule lists** — create and manage your own sets of effects.
- 🔀 **Multiple formats** — tailor rules to Advanced, Edison, GOAT, or other formats.
- 💾 **Local persistence** — saves your rule lists and selected list on your device using `UserDefaults`.
- 📖 **How to Play** guide inside the app.

## How to Play

YGO Shuffle is a **house-rule variant**, not an official Yu-Gi-Oh! format.

1. At the beginning of **each player's Standby Phase**, spin the Rule Generator.
2. Apply the generated effect to the duel.
3. The generated effect **cannot be responded to or negated** by cards or effects (the app describes this as “Spell Speed 4”).
4. After the generated effect resolves, players may activate cards and effects as normal, where permitted.
5. If the result doesn't change the game state, spin again until it does.

The default list is designed around the Advanced format, but you can customize the experience for your group.

## Getting Started

### Requirements

- A Mac with **Xcode**
- An iOS device or iOS Simulator compatible with the project's deployment target

### Run locally

1. Clone this repository:
   ```bash
   git clone https://github.com/7DavidMedina7/YgoShuffle.git
   ```
2. Open the Xcode project in the cloned repository.
3. Select an iOS simulator or connected device.
4. Build and run the app in Xcode.

## Customize Rules

Use **Manage Lists** to maintain lists for different decks, formats, or game nights. Select your desired list on the main screen, then tap **Spin for Rule**.

You can also experiment with party rules or adapt the generator for other card games.

## Built With

- **Swift**
- **SwiftUI**
- **UserDefaults** for on-device storage

## Credits

Created by **David A. Medina**.

Special thanks to **Gerardo Lopez** and **Miguel Mejia** for help with YGO Shuffle's design and rule accuracy.

Instagram: [@_davey_wavey_](https://www.instagram.com/_davey_wavey_/)

## Disclaimer

YGO Shuffle is an unofficial fan-made companion project and is not affiliated with or endorsed by Konami. Yu-Gi-Oh! is a trademark of its respective owners.

### Rule history

Tap **Rule History** on the generator screen to see your last 100 completed spins, newest first. Each result includes the rule, the source list name at the time of the spin, and its date and time. History is saved on your device across app launches. Canceled spins and re-roll messages are not recorded. Use **Clear** in the history screen and confirm to remove all saved results.

### Rule categories and filters

Tap **Categories** below the active-list selector to choose which categories can appear in a spin. Filters are saved separately for each list; all categories start enabled. Disabling every category pauses generation until you enable a category with rules. You can restore all categories with **Enable All Categories**.

In **Manage Lists**, choose a category when adding a rule or tap its pencil to edit its text and category. Existing default rules are categorized automatically; unmatched custom rules start in **Miscellaneous**. Duplicate lists copy their categories and filters. Existing saved lists are migrated when the app launches.

### Share and import rule lists

Open **Manage Lists**, then press and hold a list and choose **Share JSON** to send its file through the iOS share sheet, or **Save JSON File** to save it in Files. The file includes the list name, rule text and categories, and enabled-category filters. It does not include history.

Tap **Import Rule List** and select a JSON file to add a new list. Imports do not replace existing lists or change the active list; matching names receive an Imported suffix. Current shared files and standalone legacy rule-list JSON files are supported. Invalid files show an error without changing your lists. Files are limited to 1 MB and 1,000 rules.

### Spin settings

Open **Spin Settings** on the generator screen to toggle haptics, sound effects, quick spins, and consecutive-duplicate avoidance. Settings are saved on your device. Sound starts off and respects silent mode; haptics and duplicate avoidance start on. Quick Spin reduces the animation from 2 seconds to 0.65 seconds and the re-roll pause from 1 second to 0.3 seconds.

Duplicate avoidance compares the last completed result in saved history for the active list and excludes matching rule text when another enabled result exists. If only one distinct result is available, it can repeat. Clearing history resets the comparison. Haptics require a supported device.

### Neon spinner

The generator now features a black arcade cabinet with neon accents, a fading reel with a glowing center marker, orbit accents, and a compact result card. Classic and Quick Spin settings continue to control pacing. With iOS Reduce Motion enabled, it uses a brief static draw instead of the moving reel.

The main generator fits its controls into a single screen: category filters sit beside the list selector, and Lists, History, How to Play, and Settings share a compact row. The reel adapts to screen height and uses a side-by-side layout in landscape. Tap **Full Rule** to read longer results at full size.

The generator background is solid black. Its controls use distinct solid fills: orange Spin, blue Lists, magenta History, green How to Play, purple Settings, and teal Filters.
