//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import Foundation
import Vapor


struct SubmitAnalyzingResultResponse: Content {
    var jobs: [TranscodingJob]
    var createdAt: Date
}
