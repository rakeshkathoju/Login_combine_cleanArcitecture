//
//  AuthRepository.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Combine

protocol AuthRepository {
    // Publishes a User on successful login or fails with an Error
    func loginPublisher(username: String, password: String) -> AnyPublisher<User, Error>

    // Publishes completion when logout finishes (or fails)
    func logoutPublisher() -> AnyPublisher<Void, Never>

    // Current user snapshot; repositories may also expose a publisher for auth state changes
    var currentUser: User? { get }

    // Optional: stream of current user changes; implementers can provide a subject-backed publisher
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
}
