import XCTest
import CryptoKit
@testable import VaultMaster

@MainActor
final class VaultViewModelTests: XCTestCase {

    var vm: VaultViewModel!
    var sampleKey: SymmetricKey!

    override func setUp() {
        super.setUp()
        sampleKey = SymmetricKey(size: .bits256)
        AppState.shared.unlock(with: sampleKey)
        vm = VaultViewModel()
        // 清理已有测试数据
        vm.items = []
        vm.folders = Folder.defaults
        vm.tags = Tag.defaults
    }

    func testCreateAndEditVaultItem() {
        var item = VaultItem(title: "Twitter Account", category: .login)
        let payload = VaultItemPayload(username: "elon", password: "XPassword2026")
        vm.saveItem(item: &item, payload: payload)

        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.title, "Twitter Account")

        // 修改条目
        item.title = "X (Twitter) Account"
        let updatedPayload = VaultItemPayload(username: "elon", password: "NewXPassword2026")
        vm.saveItem(item: &item, payload: updatedPayload)

        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.title, "X (Twitter) Account")
        let decrypted = vm.getPayload(for: vm.items.first!)
        XCTAssertEqual(decrypted.password, "NewXPassword2026")
    }

    func testTrashAndRestoreCycle() {
        var item = VaultItem(title: "Temporary Account", category: .login)
        vm.saveItem(item: &item, payload: VaultItemPayload())

        XCTAssertFalse(item.isTrash)
        XCTAssertEqual(vm.count(for: .all), 1)
        XCTAssertEqual(vm.count(for: .trash), 0)

        // 移入废纸篓
        vm.deleteItem(item)
        XCTAssertEqual(vm.count(for: .all), 0)
        XCTAssertEqual(vm.count(for: .trash), 1)

        // 还原
        let trashedItem = vm.items.first!
        vm.restoreItem(trashedItem)
        XCTAssertEqual(vm.count(for: .all), 1)
        XCTAssertEqual(vm.count(for: .trash), 0)

        // 再次移入并清空废纸篓
        vm.deleteItem(vm.items.first!)
        XCTAssertEqual(vm.count(for: .trash), 1)
        vm.emptyTrash()
        XCTAssertEqual(vm.items.count, 0)
    }

    func testFilteringAndSearch() {
        let folder = Folder(name: "Dev Folder")
        let tag = Tag(name: "Urgent")
        vm.folders.append(folder)
        vm.tags.append(tag)

        var item1 = VaultItem(title: "GitHub Personal", category: .login, folderId: folder.id, tagIds: [tag.id], isFavorite: true)
        vm.saveItem(item: &item1, payload: VaultItemPayload(username: "octocat", url: "https://github.com"))

        var item2 = VaultItem(title: "AWS Console", category: .login, isFavorite: false)
        vm.saveItem(item: &item2, payload: VaultItemPayload(username: "aws_admin"))

        var item3 = VaultItem(title: "Stripe Production Key", category: .apiKey, isFavorite: true)
        vm.saveItem(item: &item3, payload: VaultItemPayload(keyId: "pk_live_123"))

        // 测试 All 过滤
        XCTAssertEqual(vm.filteredItems(for: .all, searchText: "").count, 3)

        // 测试 Favorites 过滤
        XCTAssertEqual(vm.filteredItems(for: .favorites, searchText: "").count, 2)

        // 测试 Category 过滤
        XCTAssertEqual(vm.filteredItems(for: .category(.apiKey), searchText: "").count, 1)

        // 测试 Folder 过滤
        XCTAssertEqual(vm.filteredItems(for: .folder(folder.id), searchText: "").count, 1)

        // 测试 Tag 过滤
        XCTAssertEqual(vm.filteredItems(for: .tag(tag.id), searchText: "").count, 1)

        // 测试文本搜索
        XCTAssertEqual(vm.filteredItems(for: .all, searchText: "octocat").count, 1)
        XCTAssertEqual(vm.filteredItems(for: .all, searchText: "stripe").count, 1)
        XCTAssertEqual(vm.filteredItems(for: .all, searchText: "nonexistent").count, 0)
    }

    func testSortingOptions() {
        var itemA = VaultItem(title: "Apple", category: .login)
        var itemB = VaultItem(title: "Banana", category: .login)
        var itemC = VaultItem(title: "Cherry", category: .login)

        vm.saveItem(item: &itemA, payload: VaultItemPayload())
        vm.saveItem(item: &itemB, payload: VaultItemPayload())
        vm.saveItem(item: &itemC, payload: VaultItemPayload())

        vm.sortOption = .titleAsc
        let sortedTitles = vm.filteredItems(for: .all, searchText: "").map { $0.title }
        XCTAssertEqual(sortedTitles, ["Apple", "Banana", "Cherry"])
    }
}
