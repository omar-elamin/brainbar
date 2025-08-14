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
  let brain = NSTextField(labelWithString: "🧠")
  let field = NSTextField()
  var keyMonitor: Any?
  var globalKeyMonitor: Any?
  var initialFrame: NSRect!
  let initialWidth: CGFloat = 860
  let initialHeight: CGFloat = 56

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

    // --- One blurred pill with Spotlight-like appearance
    blur.frame = window.contentView!.bounds
    blur.autoresizingMask = [.width, .height]
    blur.material = .menu        // .hudWindow for darker
    blur.state = .active
    blur.wantsLayer = true
    blur.layer?.cornerRadius = 12  // Reduced from H/2 (28) to match Spotlight
    blur.layer?.masksToBounds = true
    blur.layer?.borderWidth = 0.5
    blur.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
    window.contentView?.addSubview(blur)

    // --- Brain emoji
    brain.font = .systemFont(ofSize: 26)
    brain.textColor = .secondaryLabelColor
    brain.alignment = .center
    brain.frame = NSRect(x: 18, y: (H - 26)/2 - 1, width: 28, height: 28)
    blur.addSubview(brain)

    // --- Text field (editable, multiline capable)
    field.placeholderString = "Brain Dump"
    field.font = .systemFont(ofSize: 28, weight: .regular)
    field.textColor = .black
    field.focusRingType = .none
    field.isBordered = false
    field.drawsBackground = false
    field.isEditable = true
    field.isSelectable = true
    if let cell = field.cell as? NSTextFieldCell {
      cell.wraps = true
      cell.isScrollable = false
      cell.textColor = .textColor
    }
    field.frame = NSRect(x: 56, y: (H - 34)/2, width: W - 72, height: 34)
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

    // --- Dismiss on Enter / Esc (no focus-loss auto-close to avoid instant quits)
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
      guard let self = self else { return e }
      switch e.keyCode {
      case 53: self.quit(); return nil                 // Esc
      case 36, 76: self.commit(); return nil           // Return / keypad Enter
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
        field.frame = NSRect(x: 56, y: (initialHeight - 34)/2, width: initialWidth - 72, height: 34)
      }
      return
    }
    
    let font = field.font ?? NSFont.systemFont(ofSize: 28)
    let maxWidth = initialWidth - 72 // Account for margins and brain emoji
    
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
    let minFieldHeight: CGFloat = 34
    let calculatedFieldHeight = max(minFieldHeight, textHeight + 16) // Add padding
    
    // Calculate new window height
    let newWindowHeight = max(initialHeight, calculatedFieldHeight + 22) // Field padding in window
    
    if abs(newWindowHeight - window.frame.height) > 1 { // Only adjust if meaningful change
      // Update window frame
      var newFrame = window.frame
      let heightDiff = newWindowHeight - newFrame.height
      newFrame.size.height = newWindowHeight
      newFrame.origin.y -= heightDiff // Keep window anchored at top
      
      window.setFrame(newFrame, display: true, animate: true)
      
      // Update blur view
      blur.frame = window.contentView!.bounds
      blur.layer?.cornerRadius = 12 // Consistent Spotlight-like corner radius
      
      // Update text field frame
      field.frame = NSRect(
        x: 56,
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