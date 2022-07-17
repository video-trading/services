//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/17/22.
//

import Foundation
import common
import Vapor
import model

extension Request {
    func getDownloadURL(video: VideoInfo) async throws -> String{
        try await findObject(bucket: video.bucketName, key: video.fileName)
        
        guard let url = URL(string: video.source ?? "") else {
            throw Abort(.notFound, reason: "Cannot construct a valid url from video source: \(video.source ?? "nil")")
        }
        let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL.absoluteString
    }
    
    
    func onTranscodingSuccess(submittedData: TranscodingResult, storedData: TranscodingInfoModel) async {
           // check if object exists
           do {
               let _ = try await s3.getObject(.init(bucket: submittedData.bucketName, key: submittedData.fileName))
               storedData.status = .success
           } catch {
               storedData.status = .failed
           }
       }
    
    func findObject(bucket: String, key: String) async throws {
        do {
            let _ = try await s3.getObject(.init(bucket: bucket, key: key))
        } catch {
            throw Abort(.notFound,  reason: "The given key \(key) not found")
        }
    }
}
