//
//  VideoInfoTests.swift
//
//
//  Created by Qiwei Li on 7/13/22.
//

@testable import model
import XCTest

class VideoInfoTests: XCTestCase {
    func testVideoInfoRequest() throws {
        let request = VideoInfoRequest(title: "Hello world", labels: [])
        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(VideoInfoRequest.self, from: encoded)
        XCTAssertEqual(decoded.title, "Hello world")
        XCTAssertEqual(decoded.labels, [])
    }

    func testVideoInfoCreate() throws {
        let info = VideoInfo(title: "Hello", labels: [], description: "Hello", cover: nil, source: nil, transcoding: [], status: .encoding, statusDescription: nil, length: nil)

        let encoded = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(VideoInfo.self, from: encoded)
        XCTAssertEqual(decoded.title, info.title)
        XCTAssertEqual(decoded.labels, info.labels)
        XCTAssertEqual(decoded.description, info.description)
        XCTAssertEqual(decoded.cover, info.cover)
        XCTAssertEqual(decoded.source, info.source)
    }
}
