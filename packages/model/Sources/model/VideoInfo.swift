import Fluent
import Foundation
import Vapor


public enum VideoStatus: String, Codable {
    case success
    case failed
    case pending
    case encoding
    case canceled
    case uploaded
}

protocol VideoInfoProtocol: Content {
    var title: String { get set }
    var labels: [String] { get set }
    var description: String? { get set }
    var cover: String? { get set }
}

public struct VideoInfoRequest: VideoInfoProtocol {
    public var title: String
    public var labels: [String]
    public var description: String?
    public var cover: String?
    public var fileName: String
}

public final class VideoInfo: Model, VideoInfoProtocol {
    public static let schema = "videoInfo"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "title")
    public var title: String

    @Field(key: "labels")
    public var labels: [String]

    @OptionalField(key: "description")
    public var description: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Field(key: "status")
    public var status: VideoStatus

    @OptionalField(key: "status_description")
    public var statusDescription: String?

    @OptionalField(key: "cover")
    public var cover: String?

    @OptionalField(key: "source")
    public var source: String?

    @Field(key: "transcodings")
    public var transcoding: [TranscodingInfo]

    @OptionalField(key: "length")
    public var length: Int?

    @Field(key: "file_name")
    public var fileName: String

    @Field(key: "bucket_name")
    public var bucketName: String
    
    @OptionalField(key: "quality")
    public var quality: VideoResolution?

    public init() {}

    public init(id: UUID? = nil, title: String, labels: [String], description: String?, cover: String?,
                source: String?, transcoding: [TranscodingInfo], status: VideoStatus, statusDescription: String?,
                length: Int?, fileName: String, bucketName: String, quality: VideoResolution? = nil)
    {
        self.id = id
        self.title = title
        self.labels = labels
        self.description = description
        self.cover = cover
        self.source = source
        self.transcoding = transcoding
        self.status = status
        self.statusDescription = statusDescription
        self.length = length
        self.fileName = fileName
        self.bucketName = bucketName
        self.quality = quality
    }
}
