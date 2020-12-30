//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Omar Bassyouni on 30/12/2020.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>
public protocol HTTPClient {
    func get(url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
