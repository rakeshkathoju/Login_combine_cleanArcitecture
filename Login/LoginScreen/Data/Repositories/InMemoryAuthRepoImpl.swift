//
//  InMemoryAuthRepository.swift.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Combine

final class InMemoryAuthRepoImpl: AuthRepository {
    private var storedUser: User?
    var currentUser: User? { storedUser }

    // Publisher for user changes
    private let currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    var currentUserPublisher: AnyPublisher<User?, Never> { currentUserSubject.eraseToAnyPublisher() }

    // Public wrapper. Switch between simulated and network implementations by changing the returned publisher.
    func loginPublisher(username: String, password: String) -> AnyPublisher<User, Error> {
        // For learning: choose which one to use
        // return loginPublisherNetwork(username: username, password: password)
        return loginPublisherSimulatedDelay(username: username, password: password)
    }

    // 1) Simulated in-memory login with validation and artificial delay ("sleep")
    func loginPublisherSimulatedDelay(username: String, password: String) -> AnyPublisher<User, Error> {
        return Deferred {
            Future<User, Error> { [weak self] promise in
                guard !username.isEmpty, !password.isEmpty else {
                    promise(.failure(AuthError.invalidCredentials))
                    return
                }
                let user = User(id: UUID(), username: username)
                self?.storedUser = user
                self?.currentUserSubject.send(user)
                promise(.success(user))
            }
        }
        .delay(for: .milliseconds(400), scheduler: DispatchQueue.global())
        .eraseToAnyPublisher()
    }

    // 2) Networked login using URLSession (example). Adapt URL, body, and decoding to your backend.
    func loginPublisherNetwork(username: String, password: String) -> AnyPublisher<User, Error> {
        guard let url = URL(string: "https://example.com/login") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = LoginRequest(username: username, password: password)
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .map { User(id: $0.id, username: $0.username) }
            .handleEvents(receiveOutput: { [weak self] user in
                self?.storedUser = user
                self?.currentUserSubject.send(user)
            })
            .eraseToAnyPublisher()
    }

    func logoutPublisher() -> AnyPublisher<Void, Never> {
        return Just(())
            .delay(for: .milliseconds(150), scheduler: DispatchQueue.global())
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.storedUser = nil
                self?.currentUserSubject.send(nil)
            })
            .eraseToAnyPublisher()
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password."
        case .serverError:
            return "Server error."
        }
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let id: UUID
    let username: String
}
