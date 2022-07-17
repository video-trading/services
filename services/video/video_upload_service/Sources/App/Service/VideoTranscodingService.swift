//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/17/22.
//

import Foundation
import Vapor
import common
import model


extension Request {
    func upload(video: inout VideoInfoRequest) async throws -> UploadResponse {
        let s3URL = try URL.s3(object: video.fileName)
        video.fileName = s3URL.fileName
        
        let presignedURL = try await s3.signURL(url: s3URL.url, httpMethod: .PUT, expires: .hours(1))
        let videoInfo = video.toVideoInfo(presignedURL: s3URL.url)
        try await videoInfo.create(on: db)
        
        return UploadResponse(id: videoInfo.id!, preSignedURL: presignedURL.absoluteString)
    }
    
    
    func download(video: VideoInfo) async throws -> DownloadResponse {
        guard let sourceURL = video.source else {
            throw Abort(.badRequest, reason: "Missing source url")
        }
        let s3URL = URL(string: sourceURL)
        guard let s3URL = s3URL else {
            throw Abort(.badRequest, reason: "Source URL in incorrect format")
        }

        let presignedURL = try await s3.signURL(url: s3URL, httpMethod: .GET, expires: .hours(1))
        
        return DownloadResponse(id: video.id!, fileName: video.fileName, preSignedURL: presignedURL.absoluteString)
    }
    
    
    func delete(video: VideoInfo) async throws -> Response {
        try await deleteFile(previous: video)
        try await video.delete(on: db)
        
        return Response(status: .ok)
    }
    
    func updateStatus(video: VideoInfo, status: UpdateStatusRequest) async throws -> Response {
        switch status.status {
        case .success:
            await onUpdateStatusSuccess(previous: video)
        case .failed:
            await onUpdateStatusFailed(previous: video)
        case .canceled:
            await onUpdateStatusFailed(previous: video)
        }
        try await video.update(on: db)
        return Response(status: .accepted)
    }
}


extension Request {
    func onUpdateStatusSuccess(previous data: VideoInfo) async {
        // check if object exists
        do {
            let _ = try await s3.getObject(.init(bucket: data.bucketName, key: data.fileName))
            data.status = .uploaded
            data.statusDescription = "Video has been uploaded"
            let job = try await videoTranscoding.client.submitTranscodingRequest(id: data.id!)
            logger.info("Sent transcoding request to transcoding service: \(job)")
        } catch {
            logger.error("User submit a success status but cannot find object with name \(data.fileName)")
            data.status = .failed
            data.statusDescription = "Upload failed"
        }
    }
    
    func onUpdateStatusFailed(previous data: VideoInfo) async {
        data.status = .failed
        data.statusDescription = "Failed to upload"
    }
    
    func onUpdateStatusCancelled(previous data: VideoInfo) async {
        data.status = .canceled
        data.statusDescription = "User cancelled file upload"
    }
    
    func deleteFile(previous data: VideoInfo) async throws {
        // check if object exists
        let _ = try await s3.deleteObject(.init(bucket: Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!, key: data.fileName))
    }
}
