//
//  XCTestCase+MemeoryLeakTrackerHelper.swift
//  EssentialFeedTests
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import XCTest

extension XCTestCase {
    func checkForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential Meamory leak for instance", file: file, line: line)
        }
    }
}
