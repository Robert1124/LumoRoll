import Foundation
import XCTest
@testable import LumoRoll

final class AppAssetURLResolverTests: XCTestCase {
    func testResolvesFilmRollAndTemporaryImportPathsBelowAssetRoot() throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let resolver = AppAssetURLResolver(assetStore: assetStore)

        let filmRollURL = try resolver.resolve("film-rolls/roll-1/reference/original.jpg")
        let importURL = try resolver.resolve("tmp/imports/import-1/original.png")

        XCTAssertEqual(filmRollURL, assetStore.rootURL.appendingPathComponent("film-rolls/roll-1/reference/original.jpg"))
        XCTAssertEqual(importURL, assetStore.rootURL.appendingPathComponent("tmp/imports/import-1/original.png"))
        XCTAssertEqual(try resolver.relativePath(for: filmRollURL), "film-rolls/roll-1/reference/original.jpg")
        XCTAssertEqual(try resolver.relativePath(for: importURL), "tmp/imports/import-1/original.png")
    }

    func testRejectsUnsafeOrMalformedPaths() throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let resolver = AppAssetURLResolver(assetStore: AssetStore(baseURL: tempDirectory))

        let unsafePaths = [
            "",
            "/tmp/outside.jpg",
            "file:///tmp/outside.jpg",
            "film-rolls/../outside.jpg",
            "../outside.jpg",
            "tmp/imports//original.png",
            "tmp/imports/import 1/original.png",
            "tmp/imports/import-1/original%2Fbad.png"
        ]

        for path in unsafePaths {
            XCTAssertThrowsError(try resolver.resolve(path), "Expected \(path) to be rejected")
        }
    }

    func testRejectsMakingRelativePathForURLOutsideAssetRoot() throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let resolver = AppAssetURLResolver(assetStore: AssetStore(baseURL: tempDirectory))

        XCTAssertThrowsError(try resolver.relativePath(for: tempDirectory.appendingPathComponent("outside.jpg")))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollAppAssetURLResolverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
