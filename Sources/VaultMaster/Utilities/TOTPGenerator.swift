import Foundation
import CommonCrypto

/// TOTP (RFC 6238 / RFC 4226) 双重认证动态验证码生成器
public enum TOTPGenerator {
    
    /// 解析 TOTP 密钥（支持裸 Base32 密钥或 otpauth://totp/... URI）
    public static func cleanSecret(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("otpauth://") {
            if let components = URLComponents(string: trimmed),
               let secretItem = components.queryItems?.first(where: { $0.name.lowercased() == "secret" })?.value {
                return secretItem.replacingOccurrences(of: " ", with: "").uppercased()
            }
        }
        return trimmed.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").uppercased()
    }

    /// 生成当前 TOTP 动态码及倒计时信息
    /// - Parameters:
    ///   - secretRaw: 原始密钥输入
    ///   - period: 周期（默认 30 秒）
    ///   - digits: 位数（默认 6 位）
    /// - Returns: (6位格式化代码, 剩余秒数, 进度 0.0~1.0)
    public static func generateCurrent(secret secretRaw: String, period: TimeInterval = 30, digits: Int = 6) -> (code: String, formattedCode: String, remainingSeconds: Int, progress: Double)? {
        let cleaned = cleanSecret(secretRaw)
        guard !cleaned.isEmpty, let keyData = base32Decode(cleaned) else {
            return nil
        }

        let now = Date().timeIntervalSince1970
        let counter = UInt64(now / period)
        let remainingSeconds = Int(period) - (Int(now) % Int(period))
        let progress = Double(remainingSeconds) / period

        guard let code = generateCode(keyData: keyData, counter: counter, digits: digits) else {
            return nil
        }

        // 格式化为 "123 456" 方便阅读
        let formatted: String
        if code.count == 6 {
            let index = code.index(code.startIndex, offsetBy: 3)
            formatted = "\(code[..<index]) \(code[index...])"
        } else {
            formatted = code
        }

        return (code, formatted, remainingSeconds, progress)
    }

    // MARK: - RFC 4226 HOTP 计算

    private static func generateCode(keyData: Data, counter: UInt64, digits: Int) -> String? {
        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: MemoryLayout<UInt64>.size)

        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            counterData.withUnsafeBytes { counterBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyBytes.baseAddress, keyData.count, counterBytes.baseAddress, counterData.count, &hmac)
            }
        }

        let offset = Int(hmac[hmac.count - 1] & 0x0f)
        guard offset + 4 <= hmac.count else { return nil }

        let truncatedHash = (UInt32(hmac[offset] & 0x7f) << 24)
            | (UInt32(hmac[offset + 1] & 0xff) << 16)
            | (UInt32(hmac[offset + 2] & 0xff) << 8)
            | UInt32(hmac[offset + 3] & 0xff)

        let modulo = UInt32(pow(10.0, Double(digits)))
        let codeNum = truncatedHash % modulo
        return String(format: "%0*u", digits, codeNum)
    }

    // MARK: - Base32 解码

    private static func base32Decode(_ string: String) -> Data? {
        let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var buffer: UInt64 = 0
        var bitsLeft = 0
        var result = Data()

        for char in string.uppercased() {
            guard let index = base32Alphabet.firstIndex(of: char) else {
                if char == "=" { continue }
                return nil
            }
            let val = UInt64(base32Alphabet.distance(from: base32Alphabet.startIndex, to: index))
            buffer = (buffer << 5) | val
            bitsLeft += 5

            if bitsLeft >= 8 {
                bitsLeft -= 8
                let byte = UInt8((buffer >> bitsLeft) & 0xff)
                result.append(byte)
            }
        }

        return result.isEmpty ? nil : result
    }
}
