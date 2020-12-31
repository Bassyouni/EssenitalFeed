//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromUrl_perfromGetRequestFromURL() {
        let url = anyURL()
        
        let exp = expectation(description: "wait for requests")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, url)
            exp.fulfill()
        }
        
        makeSUT().get(url: url) { _ in }
        
        wait(for: [exp], timeout: 0.1)
    }

    func test_getFromUrl_failsOnRquestError() {
        let requestError = anyNSError()
        
        let recivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?
        
        XCTAssertEqual(recivedError?.code, requestError.code)
        XCTAssertEqual(recivedError?.domain, requestError.domain)
    }
    
    func test_getFromUrl_failOnAllInValidValues() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: AnyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: AnyHTTPURLResponse(), error: anyNSError()))
        
        
    }
    
    func test_getFromURL_succeedsWithValidDataAndHTTPURLResponse() {
        let data = anyData()
        let response = AnyHTTPURLResponse()
        let recivedValues = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(recivedValues?.data, data)
        XCTAssertEqual(recivedValues?.response.url, response.url)
        XCTAssertEqual(recivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWitEmptyDataOnHTTPURLReponseWithNilData() {
        let response = AnyHTTPURLResponse()
        let recivedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(recivedValues?.data, emptyData)
        XCTAssertEqual(recivedValues?.response.url, response.url)
        XCTAssertEqual(recivedValues?.response.statusCode, response.statusCode)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        checkForMemoryLeaks(sut)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let result = resultsFor(data: data, response: response, error: error, file: file, line: line)
    
        switch result {
        case let .failure(recivedError as NSError):
            return recivedError
            
        default:
            XCTFail("Expected failure. got \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultsFor(data: data, response: response, error: error, file: file, line: line)
        
        switch result {
        case let .success(values):
            return values
            
        default:
            XCTFail("Expected success. got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultsFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        
        let exp = expectation(description: "wait for compleiton")
        
        var storedResult: HTTPClientResult!
        sut.get(url: anyURL()) { result in
            storedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.1)
        return storedResult
    }

    private func anyURL() -> URL {
        return URL(string: "http://a-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("any Data".utf8)
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func AnyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any domain", code: 23)
    }
    
    class URLProtocolStub: URLProtocol {
        
        static private var stub: Stub?
        static private var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let error: Error?
            let data: Data?
            let response: URLResponse?
        }
        
        static func stub( data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(error: error, data: data, response: response)
        }
        
        static func startInterceptingRequests() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        static func observeRequests(observer: @escaping ((URLRequest) -> Void)) {
            requestObserver = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let observer = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
    
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }

}
