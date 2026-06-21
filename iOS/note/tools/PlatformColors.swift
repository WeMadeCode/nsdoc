//
//  PlatformColors.swift
//  note
//
//  Created by Codex on 2026/6/10.
//

#if os(macOS)
import AppKit

extension NSColor {
    static var label: NSColor { .labelColor }
    static var tertiaryLabel: NSColor { .tertiaryLabelColor }
    static var systemBackground: NSColor { .windowBackgroundColor }
    static var secondarySystemBackground: NSColor { .controlBackgroundColor }
    static var separator: NSColor { .separatorColor }
    static var systemGray3: NSColor { .systemGray }
    static var systemGray6: NSColor { .controlBackgroundColor }
}
#endif
