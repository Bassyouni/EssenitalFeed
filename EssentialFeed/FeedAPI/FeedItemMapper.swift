//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import Foundation

internal final class FeedItemMapper {
    
    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            items.map(\.feedItem)
        }
    }
    
    

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var feedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> Result<[FeedItem], Error> {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        
        return .success(root.feed)
    }
}
