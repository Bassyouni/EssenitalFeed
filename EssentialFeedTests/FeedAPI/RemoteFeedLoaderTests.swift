//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Omar Bassyouni on 28/12/2020.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        XCTAssertTrue(makeSUT().client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "www.a-url.com")
        let (client, sut) = makeSUT(url: url!)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "www.a-url.com")
        let (client, sut) = makeSUT(url: url!)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_dilversErrorOnError() {
        let (client, sut) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity) ) {
            client.complete(with: NSError(domain: "Test", code: 0))
        }
    }
    
    func test_load_dilversErrorOnNon200HttpResponse() {
        let (client, sut) = makeSUT()
        
        let samples = [199, 201, 400, 404, 500]
        
        samples.enumerated().forEach { index, code  in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                let json = makeItemsJson([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_dilversErrorOn200HTTPResponseWithInvalidJson() {
        let (client, sut) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let inValidJson = Data("".utf8)
            client.complete(withStatusCode: 200, data: inValidJson)
        }
    }
    
    func test_load_dilversNoItemsOn200HttpResponseWithEmptyJsonList() {
        let (client, sut) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJson = makeItemsJson([])
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }
    
    func test_load_dilversItemsOn200HttpResponseWithJsonObject() {
        let (client, sut) = makeSUT()
        
        let item1 = makeItem(id: UUID(),
                             imageURL: URL(string: "www.a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "www.another-url.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items)) {
            let json = makeItemsJson([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
        
    }
    
    func test_load_doesNotDilverResultAFterSutHasBeenDeallocated() {
        let url = URL(string: "www.a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults = [Result<[FeedItem], Error>]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJson([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "www.a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (client: HTTPClientSpy, sut: RemoteFeedLoader) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        checkForMemoryLeaks(client, file: file, line: line)
        checkForMemoryLeaks(sut, file: file, line: line)
        return (client, sut)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": model.id.uuidString,
            "description": model.description,
            "location": model.location,
            "image": model.imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value { acc[e.key] = value  }
        }
      
        return (model, json)
    }
    
    private func makeItemsJson(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func checkForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential Meamory leak for instance", file: file, line: line)
        }
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expctedResult: Result<[FeedItem], RemoteFeedLoader.Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")

        sut.load { recivedResult in
            switch (recivedResult, expctedResult) {
            case let (.success(recivedItems), .success(expectedItems)):
                XCTAssertEqual(recivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(recivedError as RemoteFeedLoader.Error), .failure(expectedError)):
                XCTAssertEqual(recivedError, expectedError, file: file, line: line)
            
            default:
                XCTFail("Expected result \(expctedResult) got \(recivedResult) instead", file: file, line: line)
            
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 0.1)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)]()
       
        var requestedURLs: [URL] {
            messages.map(\.url)
        }
        
        func get(url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data,  at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            
            messages[index].completion(.success((data, response)))
        }
    }
}
