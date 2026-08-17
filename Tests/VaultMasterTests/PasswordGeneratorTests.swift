import XCTest
@testable import VaultMaster

@MainActor
final class PasswordGeneratorTests: XCTestCase {

    func testRandomCharacterGenerationLength() {
        let vm = GeneratorViewModel()
        vm.mode = .randomCharacters
        vm.length = 24
        vm.generate()

        XCTAssertEqual(vm.generatedPassword.count, 24)
    }

    func testPassphraseGeneration() {
        let vm = GeneratorViewModel()
        vm.mode = .passphrase
        vm.wordCount = 4
        vm.separator = "-"
        vm.generate()

        let parts = vm.generatedPassword.split(separator: "-")
        // 4 words + 1 random number suffix = 5 parts
        XCTAssertGreaterThanOrEqual(parts.count, 4)
    }

    func testStrengthCalculation() {
        let vm = GeneratorViewModel()
        vm.generatedPassword = "abc"
        XCTAssertEqual(vm.strength, .veryWeak)

        vm.generatedPassword = "K9#m$P2!vL9@xQ1*wZ"
        XCTAssertEqual(vm.strength, .veryStrong)
    }
}
