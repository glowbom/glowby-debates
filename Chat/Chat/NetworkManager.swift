//
//  NetworkManager.swift
//  Chat
//
//  Created by Jacob Ilin on 5/15/24.
//

import Foundation

class NetworkManager {
    private var apiProvider: APIProvider
    
    init(apiProvider: APIProvider) {
        self.apiProvider = apiProvider
    }
    
    func sendMessage(message: String, sessionId: String, completion: @escaping (Result<MultiOnResponse, Error>) -> Void) {
        apiProvider.sendRequest(message: message, sessionId: sessionId, completion: completion)
    }
}

