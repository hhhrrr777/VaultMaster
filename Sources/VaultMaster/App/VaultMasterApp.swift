import SwiftUI
import AppKit

/// macOS 原生应用代理，确保窗口正常激活到前台与 Dock 点击响应
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置为标准 GUI 应用策略（显示 Dock 图标与主窗口）
        NSApp.setActivationPolicy(.regular)
        // 激活并前置应用窗口
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(self)
                    return true
                }
            }
        }
        return true
    }
}

@main
struct VaultMasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var authVM = AuthViewModel()

    init() {
        // 启动系统级安全监听（无操作超时、休眠与锁屏）
        Task { @MainActor in
            AutoLockMonitor.shared.startMonitoring()
        }
    }

    var body: some Scene {
        // MARK: - 主应用窗口
        WindowGroup("VaultMaster", id: "main-window") {
            ContentView(appState: appState, authVM: authVM)
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // 系统命令与快捷键菜单
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("新建资产") {
                    appState.startCreatingItem(category: .login)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("金库安全") {
                Button("立即锁定金库") {
                    appState.lock()
                }
                .keyboardShortcut("l", modifiers: .command)
                .disabled(!appState.isUnlocked)
            }
        }

        // MARK: - macOS Menu Bar 常驻状态栏面板
        MenuBarExtra("VaultMaster", systemImage: appState.isUnlocked ? "lock.open.fill" : "lock.fill") {
            MenuBarPopoverView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

/// 根内容视图：根据解锁状态动态切换紧凑登录与全尺寸主三栏界面
struct ContentView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !appState.isVaultInitialized {
                SetupMasterPasswordView(authVM: authVM)
                    .transition(.opacity)
            } else if !appState.isUnlocked {
                LockView(authVM: authVM)
                    .transition(.opacity)
            } else {
                MainSplitView(appState: appState)
                    .frame(minWidth: 920, idealWidth: 1040, minHeight: 580, idealHeight: 680)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isUnlocked)
        .animation(.easeInOut(duration: 0.25), value: appState.isVaultInitialized)
    }
}
