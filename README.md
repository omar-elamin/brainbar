# BrainBar

A beautiful, frictionless macOS application for instant thought capture. BrainBar appears as a floating window with elegant macOS design, allowing you to quickly jot down notes that are automatically saved to your file system.

## ✨ Features

- **Instant Access**: Appears as a floating window positioned like Spotlight
- **Beautiful Design**: Native macOS vibrancy with dynamic blur effects and proper dark/light mode support
- **Frictionless Workflow**: 
  - `Return` → Save and close
  - `Shift + Return` → New line
  - `Esc` → Close without saving
  - Click away → Auto-close
- **Organized Storage**: Notes are saved to `~/BrainDump/inbox/` organized by date
- **Markdown Format**: Notes are automatically formatted with timestamps in Markdown

## 🚀 Quick Start

### Installation

1. **Clone or download** this repository
2. **Build** the application:
   ```bash
   xcrun swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" -framework Cocoa BrainBar.swift -o ~/bin/brainbar
   ```
3. **Make executable** (if needed):
   ```bash
   chmod +x ~/bin/brainbar
   ```
4. **Run** BrainBar:
   ```bash
   ~/bin/brainbar
   ```

### Raycast Integration (Recommended)

For even faster access, use [Raycast](https://raycast.com) to launch BrainBar with any hotkey:
1. Import the provided launch script from this project into Raycast
2. Set your preferred hotkey (e.g., `⇧⌘Space`)
3. Now launch BrainBar instantly from anywhere

### Usage

1. **Launch** BrainBar - a beautiful floating window appears
2. **Type** your thought, todo, note, or idea
3. **Press Enter** to save and close, or **Esc** or click awawy to close without saving
4. **Find your notes** in `~/BrainDump/inbox/YYYY-MM-DD.md`

## 📁 File Organization

BrainBar automatically organizes your notes:

```
~/BrainDump/inbox/
├── 2024-01-15.md
├── 2024-01-16.md
└── 2024-01-17.md
```

Each note is timestamped and formatted like:
```markdown
## 14:30:25
- Your brilliant idea here

## 15:45:12
- Another thought
```

## ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Return` | Save note and close |
| `Esc` | Close without saving |

## 🎨 Design Features

- **Adaptive Blur**: Uses different materials for dark/light mode
- **Accessibility**: High contrast borders when needed
- **Smooth Animations**: Window expansion and text field adjustments
- **Native Feel**: Follows macOS design guidelines
- **Shadow Effects**: Beautiful drop shadows for depth

## 🔧 Technical Details

- **Pure Swift**: Single file, no dependencies
- **Memory Efficient**: Lightweight and fast
- **System Integration**: Proper window management and focus handling
- **File Safety**: Atomic writes with proper error handling

## 🤝 Contributing

This is a single-file Swift application. Feel free to:
- Report issues or suggestions
- Submit pull requests with improvements
- Fork and customize for your workflow

## 📝 License

Open source - feel free to use, modify, and distribute.