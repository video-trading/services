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
    var length: Float
    
    /**
     URL for the cover.
     */
    var cover: String
    
    
    var fileName: String

}


typealias TranscodingJob = TranscodingInfo

typealias TranscodingResult = TranscodingInfo
