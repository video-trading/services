//
//  TranscodingResolutionTests.swift
//  
//
//  Created by Qiwei Li on 7/14/22.
//

import XCTest
@testable import App
@testable import model

class TranscodingResolutionTests: XCTestCase {
    func testGetListOfTranscodingTargets() throws {
        let resolution: VideoResolution = .resolution144P
        let result = resolution.getListTranscodingTargets()
        XCTAssertEqual(result, [.resolution144P])
    }
    
    func testGetListOfTranscodingTargets2() throws {
        let resolution: VideoResolution = .resolution360P
        let result = resolution.getListTranscodingTargets()
        XCTAssertEqual(result, [.resolution144P, .resolution240P, .resolution360P])
    }
    
    func testGetListOfTranscodingTargets3() throws {
        let resolution: VideoResolution = .resolution1080P
        let result = resolution.getListTranscodingTargets()
        XCTAssertEqual(result, [.resolution144P, .resolution240P, .resolution360P, .resolution480P, .resolution720P, .resolution1080P])
    }
}
