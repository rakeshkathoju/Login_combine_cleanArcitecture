//
//  LoginUseCase.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Combine

protocol LoginUseCase {
    func execute(username: String, password: String) -> AnyPublisher<User, Error>
}

struct DefaultLoginUseCase: LoginUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(username: String, password: String) -> AnyPublisher<User, Error> {
        repository
            .loginPublisher(username: username, password: password)
            .eraseToAnyPublisher()
    }
}

