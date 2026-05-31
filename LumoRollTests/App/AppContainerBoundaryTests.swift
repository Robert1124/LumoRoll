import CoreGraphics
import ImageIO
import XCTest
@testable import LumoRoll

final class AppContainerBoundaryTests: XCTestCase {
    func testLiveContainerUsesConcreteStorageProcessingAndExportAdaptersWithoutSystemUI() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let container = AppContainer.makeLive(assetStore: assetStore)

        let referenceData = try appBoundaryPNGData(width: 8, height: 8, red: 210, green: 80, blue: 40)
        let createdRoll = try await container.createFilmRollUseCase.createFilmRoll(
            input: CreateFilmRollInput(
                name: "Live Adapter Roll",
                referenceImageData: referenceData,
                preferredFileExtension: "png"
            )
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: assetStore.manifestURL(for: createdRoll.id).path))
        XCTAssertEqual(createdRoll.referenceAsset.originalPath, "film-rolls/\(createdRoll.id)/reference/original.png")
        XCTAssertEqual(createdRoll.referenceAsset.thumbnailPath, "film-rolls/\(createdRoll.id)/reference/thumbnail.jpg")
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(createdRoll.referenceAsset.originalPath)), referenceData)
        XCTAssertEqual(imageType(at: assetStore.rootURL.appendingPathComponent(createdRoll.referenceAsset.thumbnailPath)), "public.jpeg")
        XCTAssertEqual(createdRoll.lut.algorithmVersion, LUT3D.defaultAlgorithmVersion)
        let samplePackage = try XCTUnwrap(createdRoll.sampleAnalysisPackage)
        XCTAssertEqual(samplePackage.algorithmVersion, LUT3D.defaultAlgorithmVersion)
        XCTAssertNil(samplePackage.modelVersion)

        let targetURL = tempDirectory.appendingPathComponent("Picked User Photo.png")
        try appBoundaryPNGData(width: 6, height: 4, red: 255, green: 0, blue: 0).write(to: targetURL)
        let updatedRoll = try await container.applyFilmRollUseCase.applyPhoto(
            input: ApplyFilmRollInput(
                filmRollID: createdRoll.id,
                originalPhotoPath: targetURL.path,
                intensity: 75
            )
        )

        let processedPhoto = try XCTUnwrap(updatedRoll.processedPhotos.first)
        XCTAssertFalse(processedPhoto.id.isEmpty)
        XCTAssertEqual(processedPhoto.originalPath, "film-rolls/\(createdRoll.id)/processed/\(processedPhoto.id)/original.png")
        XCTAssertEqual(processedPhoto.processedPath, "film-rolls/\(createdRoll.id)/processed/\(processedPhoto.id)/rendered.jpg")
        XCTAssertEqual(processedPhoto.thumbnailPath, "film-rolls/\(createdRoll.id)/processed/\(processedPhoto.id)/thumbnail.jpg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: assetStore.rootURL.appendingPathComponent(processedPhoto.originalPath).path))
        XCTAssertEqual(imageType(at: assetStore.rootURL.appendingPathComponent(processedPhoto.processedPath)), "public.jpeg")
        XCTAssertNotNil(processedPhoto.adaptiveRenderMetadata)

        let export = try await container.exportLUTUseCase.exportLUT(input: ExportLUTInput(filmRollID: createdRoll.id))

        XCTAssertEqual(export.fileURL, assetStore.rootURL.appendingPathComponent("film-rolls/\(createdRoll.id)/lut/export.cube"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: export.fileURL.path))
        let cubeText = try String(contentsOf: export.fileURL, encoding: .utf8)
        XCTAssertTrue(cubeText.contains("LUT_3D_SIZE 33"))
        XCTAssertFalse(cubeText.contains("sampleAnalysisPackage"))
        XCTAssertFalse(cubeText.contains("coverageConfidence"))
        XCTAssertFalse(cubeText.contains("adaptiveRenderMetadata"))
        XCTAssertFalse(cubeText.contains("modelVersion"))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollAppContainerBoundaryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private func appBoundaryPNGData(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> Data {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    var bytes = [UInt8]()
    bytes.reserveCapacity(width * height * 4)
    for _ in 0..<(width * height) {
        bytes.append(red)
        bytes.append(green)
        bytes.append(blue)
        bytes.append(255)
    }
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    XCTAssertTrue(CGImageDestinationFinalize(destination))
    return data as Data
}

private func imageType(at url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    return CGImageSourceGetType(imageSource) as String?
}
