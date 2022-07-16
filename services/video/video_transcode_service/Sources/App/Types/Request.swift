//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import Foundation
import Vapor
import model
import common


struct AnalyzingRequest: Content {
    /**
     Video id
     */
    var videoId: UUID
    
    /**
     Video resolution
     */
    var quality: VideoResolution
    
    /**
     Length of the video in seconds
     */
    var length: Int
    
    /**
     URL for the cover.
     */
    var cover: String
    
    
    var fileName: String

}


struct AnalyzingJob: Content {
    /**
     Pre-signed url for cover upload
     */
    var cover: String
    /**
     Pre-signed url for video download
     */
    var source: String

    
    static func fromVideo(req: Request, videoSource: String, videoId: String) async throws -> AnalyzingJob {
        let endpoint = Environment.get(ENVIRONMENT_S3_ENDPOINT)!
        let bucket = Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!
        
        let coverURL: String = "\(endpoint)/\(bucket)/cover/\(videoId).png"
        guard let url = URL(string: coverURL) else {
            throw Abort(.internalServerError, reason: "Cannot construct a valid cover url: \(coverURL)")
        }
        
        guard let presigned = try? await req.s3.signURL(url: url, httpMethod: .PUT, expires: .hours(1)) else {
            throw Abort(.internalServerError, reason: "Cannot construct a pre-signed valid cover url: \(coverURL)")
        }
        
        return AnalyzingJob(cover: presigned.absoluteString, source: videoSource)
    }
}


typealias TranscodingJob = TranscodingInfo

typealias TranscodingResult = TranscodingInfo
