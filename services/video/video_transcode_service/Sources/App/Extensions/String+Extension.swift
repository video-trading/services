//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/15/22.
//

import Foundation
import model

extension String {
    static func transcodingURL(endpoint: String ,bucket: String, object key: String, resolution: VideoResolution) -> String {
        return "\(endpoint)/\(bucket)/\(resolution.rawValue)/\(key)"
    }
    
    static func transcodingFileName(object key: String, resolution: VideoResolution) -> String {
        return "\(resolution.rawValue)/\(key)"
    }
}
