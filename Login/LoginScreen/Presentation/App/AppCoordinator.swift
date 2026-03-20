//
//  AppCoordinator.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Observation
import Combine

@MainActor
@Observable
final class AppCoordinator {
    private var cancellables = Set<AnyCancellable>()
    
    enum Route: Equatable {
        case login
        case home(User)
    }

    var route: Route

    private let authRepository: AuthRepository
    let loginUseCase: LoginUseCase

    init() {
        let repository = InMemoryAuthRepoImpl()
        self.authRepository = repository
        self.loginUseCase = DefaultLoginUseCase(repository: repository)

//        self.route = .home(User(id: UUID(uuidString: "14438CBF-774C-47F6-87C1-049B7A62E517")!, username: "name"))

        if let user = repository.currentUser {
            self.route = .home(user)
        } else {
            self.route = .login
        }
    }

    func handleLoginSuccess(user: User) {
        print("handleLoginSuccess -> user: \(user)")
        self.route  = .home(user)
    }

    func logout() {
        authRepository
            .logoutPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.route = .login
            }
            .store(in: &cancellables)
    }
}


