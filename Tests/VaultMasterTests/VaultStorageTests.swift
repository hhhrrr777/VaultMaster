import XCTest
import CryptoKit
@testable import VaultMaster

final class VaultStorageTests: XCTestCase {

    var storage: VaultStorage!

    override func setUp() {
        super.setUp()
        storage = VaultStorage.shared
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSaveAndLoadContainer() throws {
        var container = VaultDataContainer()
        let customId = UUID()
        let sampleItem = VaultItem(
            id: customId,
            title: "Test GitHub API Key",
            category: .apiKey,
            encryptedPayloadBase64: "dGVzdF9jaXBoZXJ0ZXh0"
        )
        container.items.append(sampleItem)
        container.folders.append(Folder(name: "UnitTest Folder", icon: "folder.fill", colorHex: "#FF0000"))
        container.tags.append(Tag(name: "TestTag", colorHex: "#00FF00"))

        try storage.saveContainer(container)

        let loaded = storage.loadContainer()
        XCTAssertTrue(loaded.items.contains(where: { $0.id == customId }))
        XCTAssertTrue(loaded.folders.contains(where: { $0.name == "UnitTest Folder" }))
        XCTAssertTrue(loaded.tags.contains(where: { $0.name == "TestTag" }))
    }

    func testResetDatabase() throws {
        var container = VaultDataContainer()
        container.items.append(VaultItem(title: "TempItem", category: .login))
        try storage.saveContainer(container)

        storage.resetDatabase()

        let loaded = storage.loadContainer()
        // Resetting database should return fresh container with empty items
        XCTAssertEqual(loaded.items.count, 0)
    }
}
