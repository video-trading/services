//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import Foundation
import model



extension VideoInfoRequest {
    func toVideoInfo(presignedURL: URL) -> VideoInfo {
        VideoInfo(title: title, labels: labels, description: description, cover: nil, source: presignedURL.absoluteString, transcoding: [], status: .pending, statusDescription: "Waiting user's upload", length: nil, fileName: fileName)
    }
}
