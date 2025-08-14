// ~/brainbar/BrainBar.swift
import Cocoa

// Borderless window that CAN be key/main (crucial for typing)
final class KeyWindow: NSWindow {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
  var window: KeyWindow!
  let blur = NSVisualEffectView()
  let field = NSTextField()
  var keyMonitor: Any?
  var globalKeyMonitor: Any?
  var initialFrame: NSRect!
  let initialWidth: CGFloat = 680
  let initialHeight: CGFloat = 72

  func applicationDidFinishLaunching(_: Notification) {
    // --- Size/position like Spotlight (top area)
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    let W: CGFloat = initialWidth, H: CGFloat = initialHeight, top: CGFloat = 140
    let frame = NSRect(x: screen.midX - W/2, y: screen.maxY - H - top, width: W, height: H)
    initialFrame = frame

    window = KeyWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    window.hasShadow = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.isMovableByWindowBackground = true
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true

    // --- Beautiful blurred container with macOS vibrancy
    blur.frame = window.contentView!.bounds
    blur.autoresizingMask = [.width, .height]
    
    // Dynamic material based on appearance
    let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    blur.material = isDarkMode ? .hudWindow : .sidebar
    blur.state = .active
    blur.wantsLayer = true
    blur.layer?.cornerRadius = 22
    blur.layer?.masksToBounds = true
    
    // Add subtle drop shadow
    blur.layer?.shadowColor = NSColor.black.cgColor
    blur.layer?.shadowOffset = CGSize(width: 0, height: -20)
    blur.layer?.shadowRadius = 40
    blur.layer?.shadowOpacity = 0.25
    
    // Inner hairline for high contrast only
    if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast {
      blur.layer?.borderWidth = 1
      blur.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
    }
    
    window.contentView?.addSubview(blur)


    // --- Centered text field with proper wrapping
    field.placeholderString = "Type to capture."
    field.font = .systemFont(ofSize: 23, weight: .semibold)
    field.textColor = .textColor
    field.focusRingType = .none
    field.isBordered = false
    field.drawsBackground = false
    field.isEditable = true
    field.isSelectable = true
    field.alignment = .left
    field.maximumNumberOfLines = 0  // Allow unlimited lines
    
    if let cell = field.cell as? NSTextFieldCell {
      cell.wraps = true
      cell.isScrollable = false
      cell.textColor = .textColor
      cell.usesSingleLineMode = false
      cell.lineBreakMode = .byWordWrapping
      
      // Beautiful placeholder typography
      let placeholderFont = NSFont.systemFont(ofSize: 23, weight: .regular)
      let placeholderAttributes: [NSAttributedString.Key: Any] = [
        .font: placeholderFont,
        .foregroundColor: NSColor.placeholderTextColor.withAlphaComponent(0.5)
      ]
      cell.placeholderAttributedString = NSAttributedString(string: "Type to capture.", attributes: placeholderAttributes)
    }
    
    // Start with single line height, properly centered
    let fieldPadding: CGFloat = 32
    let singleLineHeight: CGFloat = 32
    field.frame = NSRect(x: fieldPadding, y: (H - singleLineHeight)/2, width: W - (fieldPadding * 2), height: singleLineHeight)
    field.delegate = self
    blur.addSubview(field)

    // --- Take focus reliably
    NSApp.setActivationPolicy(.regular)               // allow key focus
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async {
      self.window.makeFirstResponder(self.field)
      if let textView = self.field.currentEditor() as? NSTextView {
        textView.insertionPointColor = .systemBlue
        textView.textColor = .black
      }
    }

    // --- Frictionless keyboard flow: ↵ (save), ⇧↵ (new line), Esc (dismiss)
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
      guard let self = self else { return e }
      switch e.keyCode {
      case 53: self.quit(); return nil                 // Esc
      case 36, 76:                                     // Return / keypad Enter
        if e.modifierFlags.contains(.shift) {
          // Shift+Return = new line, let it through
          return e
        } else {
          // Return = save and quit
          self.commit(); return nil
        }
      default: return e
      }
    }
    
    // --- Global key monitor for cmd+shift+space
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] e in
      guard let self = self else { return }
      // Check for cmd+shift+space (keyCode 49 is space)
      if e.keyCode == 49 && e.modifierFlags.contains([.command, .shift]) {
        self.quit()
      }
    }
    
    // --- Detect when window loses focus (click away)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey),
      name: NSWindow.didResignKeyNotification,
      object: window
    )
  }
  
  @objc private func windowDidResignKey() {
    // Small delay to avoid quitting immediately on window creation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.quit()
    }
  }
  
  // --- NSTextFieldDelegate methods for vertical expansion
  func controlTextDidChange(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField, textField == field else { return }
    adjustWindowSizeForText()
  }
  
  private func adjustWindowSizeForText() {
    let text = field.stringValue
    guard !text.isEmpty else {
      // Reset to original size if text is empty
      if window.frame.height != initialHeight {
        window.setFrame(initialFrame, display: true, animate: true)
        blur.frame = window.contentView!.bounds
        blur.layer?.cornerRadius = 12
        let fieldPadding: CGFloat = 32
        let singleLineHeight: CGFloat = 32
        field.frame = NSRect(x: fieldPadding, y: (initialHeight - singleLineHeight)/2, width: initialWidth - (fieldPadding * 2), height: singleLineHeight)
      }
      return
    }
    
    let font = field.font ?? NSFont.systemFont(ofSize: 23, weight: .semibold)
    let fieldPadding: CGFloat = 32
    let maxWidth = initialWidth - (fieldPadding * 2)
    
    // Use NSTextContainer to properly measure wrapped text
    let textContainer = NSTextContainer(size: NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
    let layoutManager = NSLayoutManager()
    let textStorage = NSTextStorage(string: text, attributes: [.font: font])
    
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    
    // Force layout and get the actual used rect
    let usedRect = layoutManager.usedRect(for: textContainer)
    let textHeight = usedRect.height
    
    // Calculate minimum field height needed
    let minFieldHeight: CGFloat = 32
    let calculatedFieldHeight = max(minFieldHeight, textHeight + 8) // Minimal padding
    
    // Calculate new window height with proper padding
    let verticalPadding: CGFloat = 20
    let newWindowHeight = max(initialHeight, calculatedFieldHeight + verticalPadding)
    
    if abs(newWindowHeight - window.frame.height) > 1 { // Only adjust if meaningful change
      // Update window frame
      var newFrame = window.frame
      let heightDiff = newWindowHeight - newFrame.height
      newFrame.size.height = newWindowHeight
      newFrame.origin.y -= heightDiff // Keep window anchored at top
      
      window.setFrame(newFrame, display: true, animate: true)
      
      // Update blur view
      blur.frame = window.contentView!.bounds
      blur.layer?.cornerRadius = 22 // Beautiful rounded corners
      
      // Update text field frame - keep it centered in the expanded window
      field.frame = NSRect(
        x: fieldPadding,
        y: (newWindowHeight - calculatedFieldHeight) / 2,
        width: maxWidth,
        height: calculatedFieldHeight
      )
    }
  }

  private func commit() {
    let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { quit(); return }
    save(text); quit()
  }

  private func quit() {
    if let m = keyMonitor { NSEvent.removeMonitor(m) }
    if let m = globalKeyMonitor { NSEvent.removeMonitor(m) }
    NotificationCenter.default.removeObserver(self)
    NSApp.terminate(nil)
  }

  private func save(_ note: String) {
    let fm = FileManager.default
    let dir = fm.homeDirectoryForCurrentUser.appendingPathComponent("BrainDump/inbox")
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

    let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
    let tf = DateFormatter(); tf.dateFormat = "HH:mm:ss"
    let file = dir.appendingPathComponent("\(df.string(from: Date())).md")
    let line = "\n## \(tf.string(from: Date()))\n- \(note)\n"

    if let data = line.data(using: .utf8) {
      if fm.fileExists(atPath: file.path), let h = try? FileHandle(forWritingTo: file) {
        h.seekToEndOfFile(); h.write(data); try? h.close()
      } else {
        try? data.write(to: file)
      }
    }
  }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)   // keep it regular for bulletproof focus
let delegate = AppDelegate()
app.delegate = delegate
app.run()