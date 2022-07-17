//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/17/22.
//

import Foundation
import Vapor


public struct AnalyzingJob: Content {
    /**
     Pre-signed url for cover upload
     */
    public var cover: String
    /**
     Pre-signed url for video download
     */
    public var source: String
    
    public init(cover: String, source: String) {
        self.cover = cover
        self.source = source
    }

    
    public static func fromVideo(req: Request, videoSource: String, videoId: String) async throws -> AnalyzingJob {
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

