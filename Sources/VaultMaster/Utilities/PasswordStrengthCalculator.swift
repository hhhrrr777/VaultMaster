import Foundation
import SwiftUI

/// 密码强度评估与计算器
public struct PasswordStrengthCalculator {
    public let level: PasswordStrengthLevel
    public let entropy: Double
    public let description: String

    public init(password: String) {
        if password.isEmpty {
            self.level = .veryWeak
            self.entropy = 0
            self.description = "请输入密码"
            return
        }

        var poolSize: Double = 0
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { poolSize += 26 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { poolSize += 26 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { poolSize += 10 }
        if password.rangeOfCharacter(from: .punctuationCharacters) != nil || password.rangeOfCharacter(from: .symbols) != nil { poolSize += 32 }

        let calculatedEntropy = Double(password.count) * log2(max(poolSize, 2))
        self.entropy = calculatedEntropy

        if calculatedEntropy < 36 || password.count < 8 {
            self.level = .veryWeak
            self.description = "极弱密码 (易被猜解)"
        } else if calculatedEntropy < 50 || password.count < 12 {
            self.level = .weak
            self.description = "较弱密码"
        } else if calculatedEntropy < 70 {
            self.level = .medium
            self.description = "中等强度"
        } else if calculatedEntropy < 90 {
            self.level = .strong
            self.description = "强密码 (\(Int(calculatedEntropy))-bit)"
        } else {
            self.level = .veryStrong
            self.description = "极强密码 (\(Int(calculatedEntropy))-bit)"
        }
    }
}
