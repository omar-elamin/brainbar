# BrainBar

A macOS menubar application for quick note-taking and thought capture.

## Features

- Global hotkey activation (Option + Space)
- Floating overlay window for quick text input
- Automatic parsing of todos, tags, mentions, and dates
- Draft persistence across sessions
- Network status monitoring
- Sentence boundary auto-save

## Building

To build BrainBar from source:

```bash
xcrun swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" -framework Cocoa BrainBar.swift -o ~/bin/brainbar
```