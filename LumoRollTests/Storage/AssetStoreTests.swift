import XCTest
@testable import LumoRoll

final class AssetStoreTests: XCTestCase {
    func testPrepareRootCreatesApplicationSupportStyleFoldersUnderBaseURL() throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let store = AssetStore(baseURL: tempDirectory)
        try store.prepareRoot()

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.rootURL.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertEqual(store.rootURL, tempDirectory.appendingPathComponent("LumoRoll", isDirectory: true))

        isDirectory = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.filmRollsURL.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertEqual(store.filmRollsURL, store.rootURL.appendingPathComponent("film-rolls", isDirectory: true))
    }

    func testGeneratedRollIDIsPathSafeAndDoesNotUseUserVisibleName() {
        let store = AssetStore(baseURL: URL(fileURLWithPath: NSTemporaryDirectory()))
        let visibleName = "Summer Roll / ../ user name"

        let id = store.generateRollID(forDisplayName: visibleName)

        XCTAssertFalse(id.contains("Summer"))
        XCTAssertFalse(id.contains(".."))
        XCTAssertFalse(id.contains("/"))
        XCTAssertNotNil(id.range(of: #"^[A-Fa-f0-9-]{36}$"#, options: .regularExpression))
        XCTAssertNotNil(UUID(uuidString: id))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollAssetStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
