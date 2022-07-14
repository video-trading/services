//
//  URLTests.swift
//  
//
//  Created by Qiwei Li on 7/13/22.
//

import XCTest
@testable import App
@testable import common
@testable import Vapor

class URLTests: XCTestCase {
    
    override func setUp() async throws {
        setenv(ENVIRONMENT_S3_ENDPOINT, "sgp1", 1)
        setenv(ENVIRONMENT_S3_BUCKET_NAME, "test", 1)
    }

    func testSimpleURL() throws {
        let url = try URL.s3(object: "abcde.mov")
        XCTAssertEqual(url.url.pathExtension, "mov")
        XCTAssertNotEqual(url.url.lastPathComponent, "abcde.mov")
    }
    
    func testSimpleURL2() throws {
        XCTAssertThrowsError(try URL.s3(object: ".mov") ) {error in
            XCTAssertNotNil(error)
            
        }
    }
    
    func testSimpleURL3() throws {
        XCTAssertThrowsError(try URL.s3(object: "") ) {error in
            XCTAssertNotNil(error)
            
        }
    }
    
    func testSimpleURL4() throws {
        XCTAssertThrowsError(try URL.s3(object: "abc efg hij klm.mov") ) {error in
            XCTAssertNotNil(error)
            
        }
    }
}
