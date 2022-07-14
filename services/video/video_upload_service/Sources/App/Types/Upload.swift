//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import Vapor

enum UploadStatus: String, Codable {
    case canceled
    case success
    case failed
}


struct UploadResponse: Content {
    var id: UUID
    var preSignedURL: String
}

struct DownloadResponse: Content {
    var id: UUID
    var fileName: String
    var preSignedURL: String
}

struct UpdateStatusRequest: Content {
    var status: UploadStatus
}
