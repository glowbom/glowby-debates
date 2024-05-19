//
//  ApiProvider.swift
//  Chat
//
//  Created by Jacob Ilin on 5/15/24.
//

import Foundation
import Combine

protocol APIProvider {
    var apiKey: String { get }
    func sendRequest(message: String, sessionId: String, completion: @escaping (Result<MultiOnResponse, Error>) -> Void)
}
