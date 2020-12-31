//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServerGetFeedResult_matchesFixedTestAccountData() {
        switch getFeedResult() {
        case let .success(feedItems)?:
            XCTAssertEqual(feedItems.count, 8)
            XCTAssertEqual(feedItems[0], expectedItem(at: 0))
            XCTAssertEqual(feedItems[1], expectedItem(at: 1))
            XCTAssertEqual(feedItems[2], expectedItem(at: 2))
            XCTAssertEqual(feedItems[3], expectedItem(at: 3))
            XCTAssertEqual(feedItems[4], expectedItem(at: 4))
            XCTAssertEqual(feedItems[5], expectedItem(at: 5))
            XCTAssertEqual(feedItems[6], expectedItem(at: 6))
            
        case let .failure(error)?:
            XCTFail("expected success got \(error) insted")
            
        default:
            XCTFail("expected success got no response instead.")
        }
    }
    
    // MARK: - Helpers
    private func getFeedResult() -> Result<[FeedItem], Error>? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let feedLoader = RemoteFeedLoader(client: client, url: testServerURL)
        
        checkForMemoryLeaks(client)
        checkForMemoryLeaks(feedLoader)
        
        let exp = expectation(description: "wait for result")
        
        var recivedResult: Result<[FeedItem], Error>?
        feedLoader.load { (result) in
            recivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        return recivedResult
    }
    
    private func expectedItem(at index: Int) -> FeedItem {
            return FeedItem(
                id: id(at: index),
                description: description(at: index),
                location: location(at: index),
                imageURL: imageURL(at: index))
        }

        private func id(at index: Int) -> UUID {
            return UUID(uuidString: [
                "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
                "BA298A85-6275-48D3-8315-9C8F7C1CD109",
                "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
                "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
                "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
                "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
                "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
                "F79BD7F8-063F-46E2-8147-A67635C3BB01"
            ][index])!
        }

        private func description(at index: Int) -> String? {
            return [
                "Description 1",
                nil,
                "Description 3",
                nil,
                "Description 5",
                "Description 6",
                "Description 7",
                "Description 8"
            ][index]
        }

        private func location(at index: Int) -> String? {
            return [
                "Location 1",
                "Location 2",
                nil,
                nil,
                "Location 5",
                "Location 6",
                "Location 7",
                "Location 8"
            ][index]
        }

        private func imageURL(at index: Int) -> URL {
            return URL(string: "https://url-\(index+1).com")!
        }
}
