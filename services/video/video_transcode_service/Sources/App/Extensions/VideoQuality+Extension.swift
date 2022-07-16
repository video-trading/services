//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import Foundation
import model


extension VideoResolution {
    /**
     Get list of transcoding targets
     */
    func getListTranscodingTargets() -> [VideoResolution ] {
        switch self {
        case .resolution144P:
            return [.resolution144P]
        case .resolution240P:
            return [.resolution144P, .resolution240P]
        case .resolution360P:
            return [.resolution144P, .resolution240P, .resolution360P]
        case .resolution480P:
            return [.resolution144P, .resolution240P, .resolution360P, .resolution480P]
        case .resolution720P:
            return [.resolution144P, .resolution240P, .resolution360P, .resolution480P, .resolution720P]
        case .resolution1080P:
            return [.resolution144P, .resolution240P, .resolution360P, .resolution480P, .resolution720P, .resolution1080P]
        case .resolution1440P:
            return [.resolution144P, .resolution240P, .resolution360P, .resolution480P, .resolution720P, .resolution1080P, .resolution1440P]
        case .resolution2160P:
            return [.resolution144P, .resolution240P, .resolution360P, .resolution480P, .resolution720P, .resolution1080P, .resolution1440P, .resolution2160P]
            
        }
    }
}
