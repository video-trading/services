//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import Vapor
import common

struct S3Response {
    var url: URL
    var fileName: String
}

extension URL {
    static func s3(object name: String) throws -> S3Response {
        let url = URL(string: name)
        guard let url = url else {
            Logger(label: "s3").critical("Input file name is not valid: \(name)")
            throw Abort(.badRequest)
        }
        
        let fileExtension = url.pathExtension
        if fileExtension.isEmpty {
            Logger(label: "s3").critical("Input file name is not valid: \(name)")
            throw Abort(.badRequest)
        }
        
        let baseName = "upload/\(UUID()).\(url.pathExtension)"
        
        let bucket = Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!
        let endpoint = Environment.get(ENVIRONMENT_S3_ENDPOINT)!
        
        let returnedURL =  URL(string: "\(endpoint)/\(bucket)/\(baseName)")
        guard let returnedURL = returnedURL else {
            Logger(label: "s3").critical("Cannot create presigned url")
            throw Abort(.badRequest)
        }
        return S3Response(url: returnedURL, fileName: baseName)
    }
}
