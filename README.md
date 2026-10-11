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
