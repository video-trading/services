//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import model
import common
import Vapor


extension VideoInfoRequest {
    func toVideoInfo(presignedURL: URL) -> VideoInfo {
        let bucketName = Environment.get(ENVIRONMENT_S3_BUCKET_NAME)!
        return VideoInfo(title: title, labels: labels, description: description, cover: nil, source: presignedURL.absoluteString, transcoding: [], status: .pending, statusDescription: "Waiting user's upload", length: nil, fileName: fileName, bucketName: bucketName)
    }
}
