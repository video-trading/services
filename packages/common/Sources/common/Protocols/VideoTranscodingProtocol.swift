//
//  File.swift
//  
//
//  Created by Qiwei Li on 7/17/22.
//

import Foundation
import Vapor

public protocol VideoTranscodingProtocol {
    func submitTranscodingRequest(id: UUID) async throws -> AnalyzingJob
}
