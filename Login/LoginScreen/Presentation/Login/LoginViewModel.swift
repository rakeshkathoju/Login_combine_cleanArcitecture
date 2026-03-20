//
//  LoginViewModel.swift
//  LoginViewModel
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Observation
import Combine

@MainActor
@Observable
final class LoginViewModel {
    private var cancellables = Set<AnyCancellable>()

    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var error: String?

    private let loginUseCase: LoginUseCase
    private let onSuccess: (User) -> Void

    init(loginUseCase: LoginUseCase, onSuccess: @escaping (User) -> Void) {
        self.loginUseCase = loginUseCase
        self.onSuccess = onSuccess
    }

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            error = "Please enter username and password"
            return
        }
        error = nil
        isLoading = true
        loginUseCase
            .execute(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.error = (error as? LocalizedError)?.errorDescription ?? "Something went wrong"
                }
            } receiveValue: { [weak self] user in
                guard let self = self else { return }
                self.onSuccess(user)
            }
            .store(in: &cancellables)
    }
}

