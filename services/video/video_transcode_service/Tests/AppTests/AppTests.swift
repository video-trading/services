@testable import App
import XCTVapor
@testable import common
@testable import model

final class AppTests: XCTestCase {
    override func setUp() async throws {
        setenv(ENVIRONMENT_DB_KEY, "mongodb://user:password@localhost:27017/video", 1)
        setenv(ENVIRONMENT_S3_REGION, "sgp1", 1)
        setenv(ENVIRONMENT_S3_ENDPOINT, "http://localhost:4566", 1)
        setenv(ENVIRONMENT_S3_BUCKET_NAME, "video-trading", 1)
        setenv(ENVIRONMENT_ACCESS_KEY, "test", 1)
        setenv(ENVIRONMENT_SECRET_KEY, "test", 1)
    }
    
    func cleanUp(app: Application) {
        try? TranscodingInfoModel.query(on: app.db).delete().wait()
    }
        
    func testTranscode() async throws {
        let app = Application(.testing)
        defer {
            cleanUp(app: app)
            app.shutdown()
        }
        try configure(app)
        
        let video = VideoInfo(title: "a", labels: [], description: nil, cover: nil, source: "http://localhost:4566/video-trading/upload/file.mov",
                              transcoding: [], status: .uploaded, statusDescription: nil, length: nil,
                              fileName: "upload/file.mov", bucketName: "video-trading")
        var videoTranscodingInfo: TranscodingInfo? = nil
        
        let  _ = try? await app.aws.s3.createBucket(.init(bucket: "video-trading"))
        let _ = try await app.aws.s3.putObject(.init(bucket: "video-trading", key: "upload/file.mov"))
        
        try await video.create(on: app.db)
        
        try app.test(.GET, "video/transcoding/result/\(video.id!)", afterResponse: { res in
            let content = try res.content.decode([TranscodingJob].self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(content.count, 0)
        })
        
        try app.test(.POST, "video/transcoding/analyzing", beforeRequest: { req in
            try req.content.encode(AnalyzingRequest(videoId: video.id!, quality: .resolution360P, length: 10, cover: "https://my_cover.png", fileName: video.fileName))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        let updatedVideo = try await VideoInfo.find(video.id, on: app.db)
        XCTAssertEqual(updatedVideo!.quality, .resolution360P)
        XCTAssertEqual(updatedVideo!.length, 10)
        XCTAssertEqual(updatedVideo!.cover, "https://my_cover.png")
        
        
        
        try app.test(.GET, "video/transcoding/result/\(video.id!)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let content = try res.content.decode([TranscodingJob].self)
            XCTAssertEqual(content.count, 3)
            videoTranscodingInfo = content.first
        })
        
        guard var videoTranscodingInfo = videoTranscodingInfo else {
            return
        }
        XCTAssertTrue(videoTranscodingInfo.fileName.contains("144/upload/file.mov"))
        
        let _ = try await app.aws.s3.putObject(.init(bucket: "video-trading", key: videoTranscodingInfo.fileName))
        try app.test(.POST, "video/transcoding/result", beforeRequest: { req in
            videoTranscodingInfo.status = .uploaded
            try req.content.encode(videoTranscodingInfo)
        }, afterResponse: { res in
            let content = try res.content.decode(TranscodingInfo.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(content.status, .success)
        })
    }
    
    func testTranscodeFailed() async throws {
        let app = Application(.testing)
        defer {
            cleanUp(app: app)
            app.shutdown()
        }
        try configure(app)
        
        let video = VideoInfo(title: "a", labels: [], description: nil, cover: nil, source: "http://localhost:4566/video-trading/upload/file2.mov",
                              transcoding: [], status: .uploaded, statusDescription: nil, length: nil,
                              fileName: "upload/file2.mov", bucketName: "video-trading")
        var videoTranscodingInfo: TranscodingInfo? = nil
        
        let  _ = try? await app.aws.s3.createBucket(.init(bucket: "video-trading"))
        let _ = try await app.aws.s3.putObject(.init(bucket: "video-trading", key: "upload/file2.mov"))
        
        try await video.create(on: app.db)
        
        try app.test(.GET, "video/transcoding/result/\(video.id!)", afterResponse: { res in
            let content = try res.content.decode([TranscodingJob].self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(content.count, 0)
        })
        
        try app.test(.POST, "video/transcoding/analyzing", beforeRequest: { req in
            try req.content.encode(AnalyzingRequest(videoId: video.id!, quality: .resolution360P, length: 10, cover: "", fileName: video.fileName))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "video/transcoding/result/\(video.id!)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let content = try res.content.decode([TranscodingJob].self)
            XCTAssertEqual(content.count, 3)
            videoTranscodingInfo = content.first
        })
        
        guard var videoTranscodingInfo = videoTranscodingInfo else {
            return
        }
        XCTAssertTrue(videoTranscodingInfo.fileName.contains("144/upload/file2.mov"))
        
        try app.test(.POST, "video/transcoding/result", beforeRequest: { req in
            videoTranscodingInfo.status = .uploaded
            try req.content.encode(videoTranscodingInfo)
        }, afterResponse: { res in
            let content = try res.content.decode(TranscodingInfo.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(content.status, .failed)
        })
    }
    
    
    func testSubmitTranscodingRequest() async throws {
        let app = Application(.testing)
        defer {
            cleanUp(app: app)
            app.shutdown()
        }
        try configure(app)
        
        let video = VideoInfo(title: "a", labels: [], description: nil, cover: nil, source: "http://localhost:4566/video-trading/upload/file3.mov",
                              transcoding: [], status: .uploaded, statusDescription: nil, length: nil,
                              fileName: "upload/file3.mov", bucketName: "video-trading")
        
        let  _ = try? await app.aws.s3.createBucket(.init(bucket: "video-trading"))
        let _ = try await app.aws.s3.putObject(.init(bucket: "video-trading", key: "upload/file3.mov"))
        
        try await video.create(on: app.db)
        
        try app.test(.POST, "video/transcoding/\(video.id!.uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let data = try res.content.decode(AnalyzingJob.self)
            XCTAssertContains(data.cover, "http://localhost:4566/video-trading/cover/\(video.id!.uuidString).png")
        })
        
        let updatedVideo = try await VideoInfo.find(video.id, on: app.db)
        XCTAssertEqual(updatedVideo!.status, .encoding)        
    }
    
    
    func testSubmitTranscodingRequestNotFound() async throws {
        let app = Application(.testing)
        defer {
            cleanUp(app: app)
            app.shutdown()
        }
        try configure(app)
        
        let video = VideoInfo(title: "a", labels: [], description: nil, cover: nil, source: "http://localhost:4566/video-trading/upload/file4.mov",
                              transcoding: [], status: .uploaded, statusDescription: nil, length: nil,
                              fileName: "upload/file4.mov", bucketName: "video-trading")
        
        let  _ = try? await app.aws.s3.createBucket(.init(bucket: "video-trading"))
        let _ = try await app.aws.s3.putObject(.init(bucket: "video-trading", key: "upload/file4.mov"))
        
        try await video.create(on: app.db)
        
        try app.test(.POST, "video/transcoding/\(UUID().uuidString)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
