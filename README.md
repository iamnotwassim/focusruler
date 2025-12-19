# Focus Ruler for KOReader

A KOReader plugin that improves reading focus by highlighting only a few lines at a time, with the rest of the page whited out. Especially helpful for readers with ADHD or anyone who experiences visual overwhelm when reading. A spinoff of the Reading Ruler plugin created by Syakhisk/thekrozzle (Github and reddit usernames, respectively). Please support his work as well.

## Features

- **Focus window mode**: Shows only one-to-ten lines at a time while reading.
- **Smart highlight detection**: Overlay automatically disappears when highlighting text
- **Flexible navigation**: 
  - Tap to move to next line
  - Swipe up/down to navigate
  - Custom gesture support via KOReader's dispatcher
- **Configurable**: Adjust number of visible lines, navigation mode, and notifications

## Installation

1. Download this `focusruler.koplugin` folder

2. Copy it to your KOReader plugins directory:

   ```
   /mnt/onboard/.adds/koreader/plugins/
   ```

3. Restart KOReader

4. Enable via **Tools → Focus Ruler → Toggle focus ruler**

## Usage

### Basic Usage

1. Open a document
2. Go to **Tools → Focus Ruler**
3. Toggle the ruler on
4. The page will gray out except for the current reading line(s)

### Navigation Modes

**Tap to move** (default):

- Tap anywhere on screen to advance one line
- Swipe up to go back one line

**Swipe to move**:

- Swipe down to advance one line
- Swipe up to go back one line

**None (custom gestures)**:

- Bind your own gestures via Settings → Gestures
- Available actions:
  - Focus Ruler: Move to next line
  - Focus Ruler: Move to previous line
  - Focus Ruler: toggle

### Settings

- **Visible lines**: Set how many lines show at once (between one and ten)
- **Navigation mode**: Choose tap, swipe, or bring-your-own
- **Notifications**: Toggle on/off notifications when enabling/disabling

## Credits

Created by Wassim with assistance from Claude (Anthropic).

## License

MIT License; feel free to modify and share.

## Contributing

Please reach out with any issues or requests.
