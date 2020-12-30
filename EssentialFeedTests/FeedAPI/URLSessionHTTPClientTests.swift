//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    let session: URLSession
    typealias HTTPClientResponse = (Data, HTTPURLResponse, Error) -> Void
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }
    
    func test_getFromUrl_perfromGetRequestFromURL() {
        let url = URL(string: "http://any-url.com")!
        
        let exp = expectation(description: "wait for requests")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url, url)
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 0.1)
    }

    func test_getFromUrl_failsOnRquestError() {
        let url = URL(string: "http://a-url.com")!
        let error = NSError(domain: "Test", code: Int.random(in: 1...999))
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "wait for compleiton")
        makeSUT().get(from: url) { result in
            switch result {
            case let .failure(recivedError as NSError):
                XCTAssertEqual(recivedError.code, error.code)
                XCTAssertEqual(recivedError.domain, error.domain)
                
            default:
                XCTFail("Expected failure with error: \(error). instead got \(result)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.1)
    }
    
    private func makeSUT() -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        checkForMemoryLeaks(sut)
        return sut
    }
    
    class URLProtocolStub: URLProtocol {
        
        static private var stub: Stub?
        static private var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let error: Error?
            let data: Data?
            let response: HTTPURLResponse?
        }
        
        static func stub( data: Data?, response: HTTPURLResponse?, error: Error?) {
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
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }

}
