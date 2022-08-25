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

extension Request: VideoTranscodingProtocol {
    public func submitTranscodingRequest(id: UUID) async throws -> AnalyzingJob {
        let video = try await VideoInfo.find(id, on: db)
        guard let video = video else {
            throw Abort(.notFound, reason: "Cannot find video with id: \(id)")
        }
        let downloadURL = try await getDownloadURL(video: video)
        let job = try await AnalyzingJob.fromVideo(req: self, videoSource: downloadURL, videoId: id.uuidString, fileName: video.fileName)
        let encodedData = try JSONEncoder().encode(job)
        
        video.status = .encoding
        try await video.update(on: self.db)
        
        try await self.mqtt.client.publish(to: Channels.analyzingWorker.rawValue, payload: .init(bytes: encodedData), qos: .atLeastOnce)
        return job
    }
    
    func submitTranscodingResult(result: TranscodingResult) async throws -> TranscodingResult {
        let storedTranscodingJob = try await TranscodingInfoModel.find(result.id, on: db)
        guard let storedTranscodingJob = storedTranscodingJob else {
            throw Abort(.badRequest, reason: "Cannot find stored transcoding job with the given id: \(result.id)")
        }
        
        switch result.status {
        case .uploaded:
            await onTranscodingSuccess(submittedData: result, storedData: storedTranscodingJob)
        default:
            storedTranscodingJob.status = .failed
        }
        
        try await storedTranscodingJob.update(on: db)
        return storedTranscodingJob.toTranscodingInfo()
    }
    
    func submitAnalyzingResult(result: AnalyzingRequest) async throws -> SubmitAnalyzingResultResponse {
        let video = try await VideoInfo.find(result.videoId, on: db)
        guard let video = video else {
            throw Abort(.notFound, reason: "Cannot find video")
        }
        
        let endpoint = Environment.get(ENVIRONMENT_S3_ENDPOINT)!
        let bucket = Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!
        try await findObject(bucket: bucket, key: result.fileName)
        
        let originalVideoSource = try await getDownloadURL(video: video)
        
        video.cover = result.cover
        video.length = result.length
        video.quality = result.quality
        try await video.update(on: db)
        
        // create a list of transcoding jobs
        let targetTranscodingJobs: [TranscodingJob] = try await result.quality.getListTranscodingTargets().concurrentMap { res async throws in
            let uploadDestinationURLString: String = .transcodingURL(endpoint: endpoint, bucket: bucket, object: result.fileName, resolution: res)
            let uploadFileName: String = .transcodingFileName(object: result.fileName, resolution: res)
            
            guard let uploadDestination = URL(string: uploadDestinationURLString) else {
                throw Abort(.internalServerError, reason: "Cannot construct a url: \(uploadDestinationURLString)")
            }
            let signedURL = try await self.s3.signURL(url: uploadDestination, httpMethod: .PUT, expires: .hours(1))
            
            return TranscodingJob(videoId:result.videoId, quality: res, bucketName: bucket, fileName: uploadFileName, source: signedURL.absoluteString, status: .pending, originalVideoSource: originalVideoSource)
        }
        
        for job in targetTranscodingJobs {
            let encoded = try JSONEncoder().encode(job)
            let transcodingInfoModel = job.toTranscodingInfoModel()
            try await transcodingInfoModel.create(on: db)
            try await mqtt.client.publish(to: Channels.transcodingWorker.rawValue, payload: .init(data: encoded), qos: .atLeastOnce)
        }
        return SubmitAnalyzingResultResponse(jobs: targetTranscodingJobs, createdAt: Date())
    }
}
