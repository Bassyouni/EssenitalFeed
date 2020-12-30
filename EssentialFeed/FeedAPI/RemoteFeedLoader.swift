//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Bassyouni on 28/12/2020.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result<[FeedItem], Swift.Error>) -> Void) {
        client.get(url: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                completion(FeedItemMapper.map(data, response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
