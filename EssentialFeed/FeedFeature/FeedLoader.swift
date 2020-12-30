//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Omar Bassyouni on 28/12/2020.
//

import Foundation

public protocol FeedLoader {
    func load(completion: @escaping (Result<[FeedItem], Error>) -> Void)
}
