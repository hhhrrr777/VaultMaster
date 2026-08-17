import SwiftUI
import AppKit

/// 禁用 macOS List / NSTableView / NSOutlineView 的字符首字母即时跳转定位 (Type-Ahead / Type-Select)
public struct DisableTypeSelectModifier: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureParentView(from: view)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureParentView(from: nsView)
        }
    }

    private func configureParentView(from view: NSView) {
        var current: NSView? = view
        while let v = current {
            if let outlineView = v as? NSOutlineView {
                outlineView.allowsTypeSelect = false
            } else if let tableView = v as? NSTableView {
                tableView.allowsTypeSelect = false
            } else if let scrollView = v as? NSScrollView {
                if let outlineView = scrollView.documentView as? NSOutlineView {
                    outlineView.allowsTypeSelect = false
                }
                if let tableView = scrollView.documentView as? NSTableView {
                    tableView.allowsTypeSelect = false
                }
            }
            current = v.superview
        }
    }
}

extension View {
    /// 禁用 macOS 原生列表的按键字符即时跳转定位（防止按 A 等字母键误触选择项）
    public func disableListTypeSelect() -> some View {
        self.background(DisableTypeSelectModifier())
    }
}
