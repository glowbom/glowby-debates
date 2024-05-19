//
//  MultiOnApi.swift
//  Chat
//
//  Created by Jacob Ilin on 5/15/24.
//

import Foundation

struct MultiOnResponse: Codable {
    var result: String
    var session_id: String
    var screenshot: String
}

class MultiOnAPI: APIProvider {
    let apiKey: String = "MULTION_KEY_GOES_HERE"
    
    func sendRequest(message: String, sessionId: String, completion: @escaping (Result<MultiOnResponse, Error>) -> Void) {
        let apiUrl = URL(string: "https://api.multion.ai/public/api/v1/browse")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X_MULTION_API_KEY")
        
        let data: [String: String] = [
            "cmd": message,
            "session_id": sessionId
        ].reduce(into: [:]) { result, element in
            if !element.value.isEmpty {
                result[element.key] = element.value
            }
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from MultiOn API"])))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(MultiOnResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
