import Foundation
import SwiftUI
import AppKit

/// 密码生成器模式
public enum GeneratorMode: String, CaseIterable, Identifiable {
    case randomCharacters = "随机字符"
    case passphrase = "密码短语"

    public var id: String { rawValue }
}

/// 密码强度级别
public enum PasswordStrengthLevel {
    case veryWeak
    case weak
    case medium
    case strong
    case veryStrong

    public var title: String {
        switch self {
        case .veryWeak: return "极弱"
        case .weak: return "较弱"
        case .medium: return "中等"
        case .strong: return "强"
        case .veryStrong: return "极强"
        }
    }

    public var color: Color {
        switch self {
        case .veryWeak: return .red
        case .weak: return .orange
        case .medium: return .yellow
        case .strong: return .blue
        case .veryStrong: return .green
        }
    }

    public var progress: Double {
        switch self {
        case .veryWeak: return 0.2
        case .weak: return 0.4
        case .medium: return 0.6
        case .strong: return 0.8
        case .veryStrong: return 1.0
        }
    }
}

/// 强密码与随机字符串生成器 ViewModel
@MainActor
public final class GeneratorViewModel: ObservableObject {
    @Published public var mode: GeneratorMode = .randomCharacters
    
    // 随机字符选项
    @Published public var length: Double = 18
    @Published public var includeUppercase: Bool = true
    @Published public var includeLowercase: Bool = true
    @Published public var includeNumbers: Bool = true
    @Published public var includeSymbols: Bool = true
    @Published public var excludeAmbiguous: Bool = false

    // 密码短语选项
    @Published public var wordCount: Double = 4
    @Published public var separator: String = "-"
    @Published public var capitalizeWords: Bool = true
    @Published public var includeNumberInPassphrase: Bool = true

    // 生成结果与状态
    @Published public var generatedPassword: String = ""
    @Published public var copiedToast: Bool = false

    // 常用安全词库 (用于生成便于记忆且极高熵值的 Passphrase)
    private let wordList: [String] = [
        "apple", "banana", "beacon", "breeze", "bridge", "bright", "button", "cabin",
        "cactus", "camel", "canyon", "castle", "cedar", "cloud", "clover", "comet",
        "coral", "crater", "crystal", "delta", "desert", "dolphin", "dragon", "eagle",
        "echo", "ember", "falcon", "feather", "forest", "fountain", "galaxy", "glacier",
        "granite", "harbor", "haven", "hawk", "horizon", "island", "jasper", "jungle",
        "lagoon", "lantern", "legend", "lotus", "meadow", "meteor", "mirage", "monarch",
        "nebula", "oasis", "ocean", "orbit", "orchid", "pacific", "panther", "pebble",
        "phoenix", "planet", "quartz", "radar", "rainbow", "raven", "reef", "ripple",
        "river", "rover", "ruby", "safari", "sapphire", "shadow", "sierra", "silver",
        "solstice", "spark", "summit", "thunder", "tiger", "timber", "topaz", "tornado",
        "tulip", "valley", "velvet", "vortex", "voyage", "walnut", "wave", "whisper",
        "willow", "winter", "zenith", "zephyr"
    ]

    public init() {
        generate()
    }

    // MARK: - 密码生成逻辑

    /// 执行密码生成
    public func generate() {
        switch mode {
        case .randomCharacters:
            generatedPassword = generateRandomCharacters()
        case .passphrase:
            generatedPassword = generatePassphrase()
        }
    }

    /// 生成随机混合字符密码
    private func generateRandomCharacters() -> String {
        var charPool = ""
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        let ambiguous: Set<Character> = ["0", "O", "o", "1", "l", "I", "|", "/", "\\", "'", "\"", "`", "~", ";", ":", "."]

        if includeUppercase { charPool.append(uppercase) }
        if includeLowercase { charPool.append(lowercase) }
        if includeNumbers { charPool.append(numbers) }
        if includeSymbols { charPool.append(symbols) }

        if excludeAmbiguous {
            charPool = String(charPool.filter { !ambiguous.contains($0) })
        }

        guard !charPool.isEmpty else {
            return "请勾选至少一种字符类型"
        }

        let targetLength = Int(length)
        var result = ""
        let poolArray = Array(charPool)

        // 确保至少包含勾选类型的各一个字符
        if includeUppercase, let char = uppercase.randomElement() { result.append(char) }
        if includeLowercase, let char = lowercase.randomElement() { result.append(char) }
        if includeNumbers, let char = numbers.randomElement() { result.append(char) }
        if includeSymbols, let char = symbols.randomElement() { result.append(char) }

        while result.count < targetLength {
            if let randomChar = poolArray.randomElement() {
                result.append(randomChar)
            }
        }

        // 随机打乱字符序列
        return String(result.shuffled().prefix(targetLength))
    }

    /// 生成密码短语 (Passphrase)
    private func generatePassphrase() -> String {
        let count = Int(wordCount)
        var selectedWords: [String] = []
        
        for _ in 0..<count {
            if var word = wordList.randomElement() {
                if capitalizeWords {
                    word = word.capitalized
                }
                selectedWords.append(word)
            }
        }

        var result = selectedWords.joined(separator: separator)
        if includeNumberInPassphrase {
            let randomNum = Int.random(in: 10...99)
            result += "\(separator)\(randomNum)"
        }
        return result
    }

    // MARK: - 密码强度评估

    /// 计算密码信息熵与强度等级
    public var strength: PasswordStrengthLevel {
        let pass = generatedPassword
        if pass.isEmpty || pass.hasPrefix("请勾选") { return .veryWeak }

        var poolSize: Double = 0
        if pass.rangeOfCharacter(from: .uppercaseLetters) != nil { poolSize += 26 }
        if pass.rangeOfCharacter(from: .lowercaseLetters) != nil { poolSize += 26 }
        if pass.rangeOfCharacter(from: .decimalDigits) != nil { poolSize += 10 }
        if pass.rangeOfCharacter(from: .punctuationCharacters) != nil || pass.rangeOfCharacter(from: .symbols) != nil { poolSize += 32 }

        let entropy = Double(pass.count) * log2(max(poolSize, 2))

        if entropy < 36 || pass.count < 8 {
            return .veryWeak
        } else if entropy < 50 || pass.count < 12 {
            return .weak
        } else if entropy < 70 {
            return .medium
        } else if entropy < 90 {
            return .strong
        } else {
            return .veryStrong
        }
    }

    // MARK: - 剪贴板复制

    /// 复制生成密码到剪贴板
    public func copyToClipboard() {
        guard !generatedPassword.isEmpty && !generatedPassword.hasPrefix("请勾选") else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedPassword, forType: .string)
        
        copiedToast = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.copiedToast = false
        }
    }
}
