//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import Foundation
import Vapor
import model

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


struct AnalyzingJob: Codable {
    /**
     Pre-signed url for cover upload
     */
    var cover: String
    /**
     Pre-signed url for video download
     */
    var source: String
}


typealias TranscodingJob = TranscodingInfo

typealias TranscodingResult = TranscodingInfo
