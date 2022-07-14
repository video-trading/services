@testable import App
@testable import common
@testable import model
import XCTVapor

final class AppTests: XCTestCase {
    override func setUp() async throws {
        setenv(ENVIRONMENT_DB_KEY, "mongodb://user:password@localhost:27017/video", 1)
        setenv(ENVIRONMENT_S3_REGION, "sgp1", 1)
        setenv(ENVIRONMENT_S3_ENDPOINT, "localhost:4566", 1)
        setenv(ENVIRONMENT_S3_BUCKET_NAME, "video-trading", 1)
        setenv(ENVIRONMENT_ACCESS_KEY, "test", 1)
        setenv(ENVIRONMENT_SECRET_KEY, "test", 1)
    }
    
    func testUpload() throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }
        try configure(app)
        var videoId: String = ""
        
        try app.test(.POST, "video/upload", beforeRequest: { req in
            try req.content.encode(VideoInfoRequest(title: "Hello world", labels: [], fileName: "test.mov"))
        }, afterResponse: { res in
            let data = try res.content.decode(UploadResponse.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertGreaterThan(data.id.uuidString.count, 1)
            XCTAssertGreaterThan(data.preSignedURL.count, 1)
            videoId = data.id.uuidString
        })
        
        try app.test(.GET, "video/status/\(videoId)") { statusResult in
            let status = try statusResult.content.decode(VideoInfo.self)
            XCTAssertEqual(status.status, .pending)
        }
        
        try app.test(.PATCH, "video/status/\(videoId)", beforeRequest: { req in
            try req.content.encode(UpdateStatusRequest(status: .success))
        }) { res in
            XCTAssertEqual(res.status, .accepted)
        }
        
        try app.test(.GET, "video/status/\(videoId)") { statusResult in
            let status = try statusResult.content.decode(VideoInfo.self)
            XCTAssertEqual(status.status, .failed)
        }
        
    }
    
    func testDownload() async throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }
        try configure(app)
        
        let info = VideoInfo(title: "Mock", labels: [], description: nil, cover: nil, source: "https://localhost:4566/video-trading/test.mov", transcoding: [], status: .uploaded, statusDescription: nil, length: nil, fileName: "test.mov")
        try await info.create(on: app.db)
        
        try app.test(.GET, "video/download/\(info.id!.uuidString)") { res in
            XCTAssertEqual(res.status, .ok)
            
            let downloadResponse = try res.content.decode(DownloadResponse.self)
            XCTAssertGreaterThan(downloadResponse.preSignedURL.count, 1)
            XCTAssertEqual(downloadResponse.id.uuidString, info.id?.uuidString)
        }
    }
}
