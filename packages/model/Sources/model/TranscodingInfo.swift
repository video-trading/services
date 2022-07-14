//
//  File.swift
//
//
//  Created by Qiwei Li on 7/14/22.
//

import Fluent
import Foundation
import Vapor

public enum TranscodingStatus: String, Codable {
    case pending
    case transcoding
    case transcodeFinished
    case pendingUpload
    case uploaded

    case failed
    case success
}

public enum VideoResolution: String, Codable {
    case resolution144P = "144"
    case resolution240P = "240"
    case resolution360P = "360"
    case resolution480P = "480"
    case resolution720P = "720"
    case resolution1080P = "1080"
    case resolution1440P = "1440"
    case resolution2160P = "2160"
}

protocol TranscodingInfoProtocol: Content {
    var videoId: UUID { get set }
    var quality: VideoResolution { get set }
    var bucketName: String { get set }
    var fileName: String { get set }
    var createdAt: Date? { get set }
}

public struct TranscodingInfo: TranscodingInfoProtocol {
    public var id: UUID
    public var videoId: UUID
    public var quality: VideoResolution
    public var bucketName: String
    public var fileName: String
    public var createdAt: Date?
    public var status: TranscodingStatus
    /**
     Original video url
     */
    public var originalVideoSource: String?

    /**
     Will be a pre-signed url for upload and download
     */
    public var source: String?

    public init(id: UUID? = nil, videoId: UUID, quality: VideoResolution, bucketName: String, fileName: String, source: String?, status: TranscodingStatus, originalVideoSource: String?) {
        self.id = id ?? UUID()
        self.videoId = videoId
        self.quality = quality
        self.bucketName = bucketName
        self.fileName = fileName
        self.source = source
        self.status = status
        self.originalVideoSource = originalVideoSource
    }

    public func toTranscodingInfoModel() -> TranscodingInfoModel {
        return TranscodingInfoModel(
            id: id,
            videoId: videoId,
            quality: quality,
            bucketName: bucketName,
            fileName: fileName
        )
    }
}

public final class TranscodingInfoModel: Model, TranscodingInfoProtocol {
    public static let schema = "transcodingInfo"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "videoId")
    public var videoId: UUID

    @Field(key: "quality")
    public var quality: VideoResolution

    @Field(key: "bucketName")
    public var bucketName: String

    @Field(key: "fileName")
    public var fileName: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Field(key: "status")
    public var status: TranscodingStatus

    public init() {}

    public init(
        id: UUID? = nil,
        videoId: UUID,
        quality: VideoResolution,
        bucketName: String,
        fileName: String,
        status: TranscodingStatus = .pending
    ) {
        self.id = id
        self.videoId = videoId
        self.quality = quality
        self.bucketName = bucketName
        self.fileName = fileName
        self.status = status
    }

    public func toTranscodingInfo() -> TranscodingInfo {
        TranscodingInfo(id: id!, videoId: videoId, quality: quality, bucketName: bucketName, fileName: fileName, source: nil, status: status, originalVideoSource: nil)
    }
}
