import XCTest
@testable import client
@testable import common

class HappyPathTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setenv(ENVIRONMENT_TRANSCODING_URL, "https://video.mock-api-services.workers.dev", 1)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVideoTranscoding() async throws {
        let uuid = UUID()
        let transcodingClient = VideoTranscodingClient()
        try transcodingClient.initialize()
        let result = try await transcodingClient.submitTranscodingRequest(id: uuid)
        XCTAssertNotNil(result.cover)
        XCTAssertNotNil(result.source)

    }
}
