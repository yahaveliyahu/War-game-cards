# War Game Cards 🃏

A two-player iOS card game built with UIKit and Storyboard

## About the Game

The player competes against the computer over 10 rounds. Each round, both sides draw a card and the higher value wins the round. The player with the most points after 10 rounds wins the game.

## How It Works

- On launch, the player enters their name
- The app uses **Core Location** to detect the player's real-world position and assign them to the **East Side** or **West Side**
- The player draws from a **red deck** (diamonds + hearts + red joker)
- The computer draws from a **black deck** (clubs + spades + black joker)
- Each round lasts 5 seconds before the next round begins automatically
- After 10 rounds, the result screen shows the winner and final score

## Card Values

| Card | Value |
|------|-------|
| Ace | 1 |
| 2–10 | Face value |
| Jack | 11 |
| Queen | 12 |
| King | 13 |
| Joker | 14 |

## War Rule (Tie-Breaking)

If both players draw cards of equal value, the real War Game rules apply:
- 3 cards are placed face-down on each side
- The 4th card is revealed and compared
- If another tie occurs, the war repeats

## Sound & Music

The app includes full audio support:
- 🎵 Background music — plays from the Welcome screen through the entire game, pauses when the app goes to background and resumes on return
- 🃏 Card flip sound — plays every time cards are revealed each round
- ⚔️ War sound — plays when the 3 face-down war cards animate
- 🏆 Victory sound — plays when the result screen appears, replacing the background music

## Watch the App in Action

▶️ **Demo video:** [Click here to watch the video](https://youtu.be/K8ZYcBrBw_0)

## Screens

1. **Welcome Screen** — Enter name, detect location, choose side
2. **Game Screen** — 10 rounds with card flip animations, timer, and round result toasts
3. **Result Screen** — Winner announcement or tie, with final score and back to menu button

## Built With

- Swift
- UIKit
- Storyboard + Auto Layout
- Core Location
- Xcode 26 / iOS 26.5
