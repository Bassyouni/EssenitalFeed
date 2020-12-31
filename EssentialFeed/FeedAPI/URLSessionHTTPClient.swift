//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    typealias HTTPClientResponse = (Data, HTTPURLResponse, Error) -> Void
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct InValidResponseCase: Error {}
    
    public func get(url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let httpURLResponse = response as? HTTPURLResponse {
                completion(.success((data, httpURLResponse)))
            }
            else {
                completion(.failure(InValidResponseCase()))
            }
        }.resume()
    }
}
