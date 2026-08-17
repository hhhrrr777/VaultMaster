import Foundation
import AppKit
import SwiftUI

/// 自动锁定与系统事件监听管理器
@MainActor
public final class AutoLockMonitor {
    public static let shared = AutoLockMonitor()

    private var timer: Timer?
    private var eventMonitor: Any?
    private let appState = AppState.shared

    private init() {}

    /// 启动所有安全事件监听
    public func startMonitoring() {
        stopMonitoring()

        // 1. 注册无操作活动监听
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown, .scrollWheel]
        ) { [weak self] event in
            self?.appState.recordUserActivity()
            return event
        }

        // 2. 监听系统休眠与锁屏通知
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleSystemSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleSystemSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        // 3. 监听 macOS 锁屏事件
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleScreenLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        // 4. 启动周期性超时检测计时器 (每 5 秒校验一次)
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkInactivityTimeout()
            }
        }
    }

    /// 停止监听
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 事件处理

    @objc private func handleSystemSleep() {
        Task { @MainActor in
            appState.lock()
        }
    }

    @objc private func handleScreenLock() {
        Task { @MainActor in
            appState.lock()
        }
    }

    /// 检查是否超出用户设定的无操作超时时间
    private func checkInactivityTimeout() {
        guard appState.isUnlocked else { return }
        let timeoutMinutes = appState.autoLockMinutes
        guard timeoutMinutes > 0 else { return } // 0 为永不自动锁定

        let elapsedSeconds = Date().timeIntervalSince(appState.lastActiveDate)
        if elapsedSeconds >= Double(timeoutMinutes * 60) {
            appState.lock()
        }
    }
}
